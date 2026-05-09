#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/deploy-dry-run-$TS.md"

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

echo "# Deploy Dry Run Report" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

echo "[INFO] start deploy dry run"
run_step "Env check" ./scripts/day12_env_check.sh "$ENV_FILE"
run_step "CI suite" ./scripts/day14_ci_suite.sh
run_step "Cleanup report generation" ./scripts/day32_asset_cleanup_report.sh 24 tmp/reports

echo "" >> "$REPORT_PATH"
echo "[OK] dry run completed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
