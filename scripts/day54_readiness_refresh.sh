#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$REPORT_DIR/day54-readiness-refresh-$TS.md"
OUT_JSON="$REPORT_DIR/day54-readiness-refresh-$TS.json"

declare -a STEP_RESULTS=()

run_step() {
  local name="$1"
  shift
  echo "[STEP] $name"
  if "$@"; then
    STEP_RESULTS+=("$name:passed")
    echo "- [x] $name" >> "$OUT_MD"
  else
    STEP_RESULTS+=("$name:failed")
    echo "- [ ] $name (FAILED)" >> "$OUT_MD"
    write_json "failed"
    echo "[ERROR] step failed: $name"
    exit 1
  fi
}

write_json() {
  local status="$1"
  python3 - <<'PY' "$OUT_JSON" "$TS" "$status" "${STEP_RESULTS[@]}"
import json
import sys
from pathlib import Path

out = Path(sys.argv[1])
ts = sys.argv[2]
status = sys.argv[3]
steps = []
for raw in sys.argv[4:]:
    name, result = raw.split(":", 1)
    steps.append({"name": name, "result": result})

readiness_path = Path("tmp/reports/day53-deploy-readiness-latest.json")
readiness = {}
if readiness_path.exists():
    readiness = json.loads(readiness_path.read_text(encoding="utf-8"))

payload = {
    "status": status,
    "generated_at_utc": ts,
    "steps": steps,
    "readiness": {
        "path": str(readiness_path),
        "decision": readiness.get("decision", "missing"),
        "block_reasons": readiness.get("block_reasons", []),
    },
}
out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
PY
}

echo "# Day54 Readiness Refresh Report" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- env_file: $ENV_FILE" >> "$OUT_MD"
echo "" >> "$OUT_MD"

run_step "Refresh release health bundle (Day45)" ./scripts/day45_release_health_bundle.sh "$REPORT_DIR" "$REPORT_DIR"
run_step "Refresh incident watcher (Day47)" ./scripts/day47_incident_watcher.sh "$ENV_FILE" "$REPORT_DIR"
run_step "Refresh deploy approval gate (Day48)" ./scripts/day48_deploy_approval_gate.sh "$ENV_FILE" "$REPORT_DIR"
run_step "Refresh ops manifest (Day52)" ./scripts/day52_ops_report_manifest.sh "$REPORT_DIR" "$REPORT_DIR"
run_step "Refresh deploy readiness report (Day53)" ./scripts/day53_deploy_readiness_report.sh "$REPORT_DIR" "$REPORT_DIR"

write_json "passed"

echo "" >> "$OUT_MD"
echo "## Final Readiness" >> "$OUT_MD"
python3 - <<'PY' >> "$OUT_MD"
import json
from pathlib import Path

path = Path("tmp/reports/day53-deploy-readiness-latest.json")
if path.exists():
    data = json.loads(path.read_text(encoding="utf-8"))
    print(f"- decision: {data.get('decision', 'missing')}")
    reasons = data.get("block_reasons", [])
    if reasons:
        print("- block_reasons:")
        for reason in reasons:
            print(f"  - {reason}")
    else:
        print("- block_reasons: none")
else:
    print("- decision: missing")
PY

echo "" >> "$OUT_MD"
echo "[OK] Day54 readiness refresh completed" | tee -a "$OUT_MD"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
