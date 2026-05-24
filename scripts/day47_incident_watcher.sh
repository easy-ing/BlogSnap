#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$REPORT_DIR/day47-incident-summary-$TS.md"
OUT_JSON="$REPORT_DIR/day47-incident-summary-$TS.json"

HEALTH_JSON="$REPORT_DIR/release-health-latest.json"
NOISE_JSON="$(ls -1 "$REPORT_DIR"/day46-alert-noise-review-*.json 2>/dev/null | sort | tail -n1 || true)"

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

echo "# Day47 Incident Summary" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- env_file: $ENV_FILE" >> "$OUT_MD"
echo "- report_dir: $REPORT_DIR" >> "$OUT_MD"
echo "" >> "$OUT_MD"

run_step "Env sanity check" ./scripts/day12_env_check.sh "$ENV_FILE"
run_step "Release health latest exists" test -f "$HEALTH_JSON"
run_step "Day46 noise review exists" test -n "$NOISE_JSON"

python3 - <<'PY' "$HEALTH_JSON" "$NOISE_JSON" "$OUT_JSON" "$OUT_MD"
import json
import sys
from pathlib import Path

health_path = Path(sys.argv[1])
noise_path = Path(sys.argv[2])
out_json = Path(sys.argv[3])
out_md = Path(sys.argv[4])

health = json.loads(health_path.read_text(encoding="utf-8"))
noise = json.loads(noise_path.read_text(encoding="utf-8"))

overall = health.get("overall", "unknown")
noise_metrics = noise.get("metrics", {})
forward_success_rate = float(noise_metrics.get("forward_success_rate", 1.0))
forward_fail_ratio = float(noise_metrics.get("forward_fail_ratio", 0.0))

reasons = []
if overall != "ok":
    reasons.append(f"release health overall is '{overall}'")
if forward_success_rate < 0.98:
    reasons.append(f"forward_success_rate below threshold: {forward_success_rate:.4f}")
if forward_fail_ratio > 0.05:
    reasons.append(f"forward_fail_ratio above threshold: {forward_fail_ratio:.4f}")

incident = len(reasons) > 0

result = {
    "status": "ok",
    "incident_detected": incident,
    "sources": {
        "release_health_latest": str(health_path),
        "day46_noise_latest": str(noise_path),
    },
    "signal": {
        "overall": overall,
        "forward_success_rate": forward_success_rate,
        "forward_fail_ratio": forward_fail_ratio,
    },
    "reasons": reasons,
}

out_json.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

with out_md.open("a", encoding="utf-8") as f:
    f.write("## Incident Decision\n")
    f.write(f"- incident_detected: {incident}\n")
    f.write(f"- overall: {overall}\n")
    f.write(f"- forward_success_rate: {forward_success_rate:.4f}\n")
    f.write(f"- forward_fail_ratio: {forward_fail_ratio:.4f}\n")
    if reasons:
        f.write("\n## Reasons\n")
        for idx, reason in enumerate(reasons, start=1):
            f.write(f"{idx}. {reason}\n")
PY

INCIDENT="$(python3 - <<'PY' "$OUT_JSON"
import json,sys
data=json.load(open(sys.argv[1], encoding="utf-8"))
print("yes" if data.get("incident_detected") else "no")
PY
)"

if [[ "$INCIDENT" == "yes" ]]; then
  run_step "Recovery auto-run (Day41 all scenario)" bash -lc "SCENARIO=all ./scripts/day41_gameday_recovery.sh \"$ENV_FILE\" \"$REPORT_DIR\""
  echo "" >> "$OUT_MD"
  echo "## Auto Recovery" >> "$OUT_MD"
  echo "- executed: yes" >> "$OUT_MD"
else
  echo "" >> "$OUT_MD"
  echo "## Auto Recovery" >> "$OUT_MD"
  echo "- executed: no (no incident signal)" >> "$OUT_MD"
fi

echo "" >> "$OUT_MD"
echo "[OK] Day47 incident watcher completed" | tee -a "$OUT_MD"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
