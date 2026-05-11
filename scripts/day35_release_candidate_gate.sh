#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_MD_PATH="$REPORT_DIR/release-candidate-gate-$TS.md"
REPORT_JSON_PATH="$REPORT_DIR/release-candidate-gate-$TS.json"

PYTHON_BIN="python3"
if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="python3.11"
fi

declare -a STEP_RESULTS=()

run_step() {
  local name="$1"
  shift
  echo "[STEP] $name"
  if "$@"; then
    echo "- [x] $name" >> "$REPORT_MD_PATH"
    STEP_RESULTS+=("$name:passed")
  else
    echo "- [ ] $name (FAILED)" >> "$REPORT_MD_PATH"
    STEP_RESULTS+=("$name:failed")
    write_json "failed"
    echo "[ERROR] step failed: $name"
    exit 1
  fi
}

write_json() {
  local status="$1"
  "$PYTHON_BIN" - <<'PY' "$REPORT_JSON_PATH" "$status" "$TS" "$ENV_FILE" "$PYTHON_BIN" "${STEP_RESULTS[@]}"
import json
import sys

path = sys.argv[1]
status = sys.argv[2]
ts = sys.argv[3]
env_file = sys.argv[4]
python_bin = sys.argv[5]
steps = sys.argv[6:]

step_items = []
for raw in steps:
    if ":" in raw:
        name, result = raw.split(":", 1)
        step_items.append({"name": name, "result": result})

payload = {
    "status": status,
    "generated_at_utc": ts,
    "env_file": env_file,
    "python_bin": python_bin,
    "steps": step_items,
}

with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
PY
}

echo "# Release Candidate Gate Report" > "$REPORT_MD_PATH"
echo "" >> "$REPORT_MD_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_MD_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_MD_PATH"
echo "- python_bin: $PYTHON_BIN" >> "$REPORT_MD_PATH"
echo "" >> "$REPORT_MD_PATH"

run_step "Deploy dry-run" ./scripts/day34_deploy_dry_run.sh "$ENV_FILE" "$REPORT_DIR"

if [[ -f "frontend/package.json" ]]; then
  run_step "Frontend build" bash -lc 'cd frontend && npm run build'
else
  echo "- [x] Frontend build (SKIPPED: no frontend/package.json)" >> "$REPORT_MD_PATH"
  STEP_RESULTS+=("Frontend build:skipped")
fi

run_step "Schema compile check" "$PYTHON_BIN" -m compileall -q backend tests monitoring blogsnap app.py main.py

write_json "passed"

echo "" >> "$REPORT_MD_PATH"
echo "[OK] release candidate gate passed" | tee -a "$REPORT_MD_PATH"
echo "[INFO] report markdown: $REPORT_MD_PATH"
echo "[INFO] report json: $REPORT_JSON_PATH"
