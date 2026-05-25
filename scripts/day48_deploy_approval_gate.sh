#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$REPORT_DIR/day48-deploy-approval-$TS.md"
OUT_JSON="$REPORT_DIR/day48-deploy-approval-$TS.json"
LATEST_MD="$REPORT_DIR/day48-deploy-approval-latest.md"
LATEST_JSON="$REPORT_DIR/day48-deploy-approval-latest.json"

pick_latest() {
  local pattern="$1"
  ls -1 "$REPORT_DIR"/$pattern 2>/dev/null | sort | tail -n1 || true
}

extract_status_line() {
  local path="$1"
  local line
  line="$(grep -E '^\[OK\]|FAILED|passed|completed' "$path" | tail -n1 || true)"
  if [[ -z "$line" ]]; then
    line="(status line not found)"
  fi
  echo "$line"
}

run_step() {
  local name="$1"
  shift
  echo "[STEP] $name"
  if "$@"; then
    echo "- [x] $name" >> "$OUT_MD"
  else
    echo "- [ ] $name (FAILED)" >> "$OUT_MD"
    echo "[ERROR] step failed: $name"
    exit 1
  fi
}

echo "# Day48 Deploy Approval Gate" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- env_file: $ENV_FILE" >> "$OUT_MD"
echo "" >> "$OUT_MD"

run_step "Env sanity check" ./scripts/day12_env_check.sh "$ENV_FILE"

D42_MD="$(pick_latest "day42-go-live-*.md")"
D47_JSON="$(pick_latest "day47-incident-summary-*.json")"
D45_JSON="$REPORT_DIR/release-health-latest.json"

run_step "Day42 report exists" test -f "$D42_MD"
run_step "Day47 summary exists" test -f "$D47_JSON"
run_step "Release health latest exists" test -f "$D45_JSON"

STATUS_D42="$(extract_status_line "$D42_MD")"

python3 - <<'PY' "$OUT_JSON" "$OUT_MD" "$D45_JSON" "$D47_JSON" "$D42_MD" "$STATUS_D42"
import json
import sys
from pathlib import Path

out_json = Path(sys.argv[1])
out_md = Path(sys.argv[2])
release_health_path = Path(sys.argv[3])
incident_path = Path(sys.argv[4])
day42_md_path = Path(sys.argv[5])
day42_status = sys.argv[6]

release_health = json.loads(release_health_path.read_text(encoding="utf-8"))
incident = json.loads(incident_path.read_text(encoding="utf-8"))

overall = str(release_health.get("overall", "unknown"))
incident_detected = bool(incident.get("incident_detected", False))
incident_reasons = incident.get("reasons", []) or []

reasons = []
if overall != "ok":
    reasons.append(f"release health overall is '{overall}'")
if incident_detected:
    reasons.append("incident watcher detected risk signal")
if "FAILED" in day42_status or "failed" in day42_status:
    reasons.append("day42 go-live report indicates failure")

decision = "approved" if not reasons else "blocked"

result = {
    "status": "ok",
    "decision": decision,
    "sources": {
        "release_health_latest_json": str(release_health_path),
        "incident_summary_json": str(incident_path),
        "day42_go_live_md": str(day42_md_path),
    },
    "signals": {
        "release_health_overall": overall,
        "incident_detected": incident_detected,
        "day42_status_line": day42_status,
        "incident_reasons": incident_reasons,
    },
    "block_reasons": reasons,
}

out_json.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

with out_md.open("a", encoding="utf-8") as f:
    f.write("## Decision\n")
    f.write(f"- decision: {decision}\n")
    f.write(f"- release_health_overall: {overall}\n")
    f.write(f"- incident_detected: {incident_detected}\n")
    f.write(f"- day42_status: {day42_status}\n")
    if reasons:
        f.write("\n## Block Reasons\n")
        for i, r in enumerate(reasons, 1):
            f.write(f"{i}. {r}\n")
    else:
        f.write("\n## Block Reasons\n- none\n")
PY

cp "$OUT_MD" "$LATEST_MD"
cp "$OUT_JSON" "$LATEST_JSON"

echo "" >> "$OUT_MD"
echo "[OK] Day48 deploy approval gate completed" | tee -a "$OUT_MD"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
