#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/release-candidate-gate-$TS.md"

PYTHON_BIN="python3"
if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="python3.11"
fi

run_step() {
  local name="$1"
  shift
  echo "[STEP] $name"
  if "$@"; then
    echo "- [x] $name" >> "$REPORT_PATH"
  else
    echo "- [ ] $name (FAILED)" >> "$REPORT_PATH"
    echo "[ERROR] step failed: $name"
    exit 1
  fi
}

echo "# Release Candidate Gate Report" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "- python_bin: $PYTHON_BIN" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

run_step "Deploy dry-run" ./scripts/day34_deploy_dry_run.sh "$ENV_FILE" "$REPORT_DIR"

if [[ -f "frontend/package.json" ]]; then
  run_step "Frontend build" bash -lc 'cd frontend && npm run build'
else
  echo "- [x] Frontend build (SKIPPED: no frontend/package.json)" >> "$REPORT_PATH"
fi

run_step "Schema compile check" "$PYTHON_BIN" -m compileall -q backend tests monitoring blogsnap app.py main.py

echo "" >> "$REPORT_PATH"
echo "[OK] release candidate gate passed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
