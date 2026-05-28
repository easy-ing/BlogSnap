#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$REPORT_DIR/day50-ops-suite-$TS.md"
OUT_JSON="$REPORT_DIR/day50-ops-suite-$TS.json"

declare -a STEP_RESULTS=()
declare -a STEP_REPORTS=()

run_step() {
  local name="$1"
  local cmd="$2"
  local pattern="$3"

  echo "[STEP] $name"
  if bash -lc "$cmd"; then
    STEP_RESULTS+=("$name:passed")
    local latest_report=""
    if [[ -n "$pattern" ]]; then
      latest_report="$(ls -1 "$REPORT_DIR"/$pattern 2>/dev/null | sort | tail -n1 || true)"
    fi
    STEP_REPORTS+=("$name:$latest_report")
    echo "- [x] $name" >> "$OUT_MD"
  else
    STEP_RESULTS+=("$name:failed")
    STEP_REPORTS+=("$name:")
    echo "- [ ] $name (FAILED)" >> "$OUT_MD"
    write_json "failed"
    echo "[ERROR] step failed: $name"
    exit 1
  fi
}

write_json() {
  local suite_status="$1"
  python3 - <<'PY' "$OUT_JSON" "$TS" "$suite_status" "${STEP_RESULTS[@]}" "::" "${STEP_REPORTS[@]}"
import json
import sys

out = sys.argv[1]
ts = sys.argv[2]
suite_status = sys.argv[3]
raw = sys.argv[4:]

sep = raw.index("::") if "::" in raw else len(raw)
results_raw = raw[:sep]
reports_raw = raw[sep + 1 :] if sep < len(raw) else []

result_map = {}
for item in results_raw:
    if ":" in item:
        name, status = item.split(":", 1)
        result_map[name] = status

report_map = {}
for item in reports_raw:
    if ":" in item:
        name, path = item.split(":", 1)
        report_map[name] = path

steps = []
for name, status in result_map.items():
    steps.append(
        {
            "name": name,
            "result": status,
            "report_path": report_map.get(name, ""),
        }
    )

payload = {
    "status": suite_status,
    "generated_at_utc": ts,
    "steps": steps,
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
PY
}

echo "# Day50 Ops Suite Report" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- env_file: $ENV_FILE" >> "$OUT_MD"
echo "" >> "$OUT_MD"

run_step "Release health bundle (Day45)" "./scripts/day45_release_health_bundle.sh \"$REPORT_DIR\" \"$REPORT_DIR\"" "release-health-*.md"
run_step "Alert noise review (Day46)" "./scripts/day46_alert_noise_review.sh \"$ENV_FILE\" \"$REPORT_DIR\"" "day46-alert-noise-review-*.md"
run_step "Incident watcher (Day47)" "./scripts/day47_incident_watcher.sh \"$ENV_FILE\" \"$REPORT_DIR\"" "day47-incident-summary-*.md"
run_step "Deploy approval gate (Day48)" "./scripts/day48_deploy_approval_gate.sh \"$ENV_FILE\" \"$REPORT_DIR\"" "day48-deploy-approval-*.md"
run_step "Retro autofill (Day49)" "./scripts/day49_retro_autofill.sh \"$REPORT_DIR\" \"$REPORT_DIR\"" "day49-retro-autofill-*.md"

write_json "passed"

echo "" >> "$OUT_MD"
echo "## Step Reports" >> "$OUT_MD"
for entry in "${STEP_REPORTS[@]}"; do
  name="${entry%%:*}"
  path="${entry#*:}"
  echo "- $name: ${path:-N/A}" >> "$OUT_MD"
done

echo "" >> "$OUT_MD"
echo "[OK] Day50 ops suite completed" | tee -a "$OUT_MD"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
