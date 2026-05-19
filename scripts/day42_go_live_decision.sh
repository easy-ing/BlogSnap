#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/day42-go-live-$TS.md"

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

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]]
}

echo "# Day42 Go-Live Decision Report" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

run_step "Refresh RC gate report" ./scripts/day35_release_candidate_gate.sh "$ENV_FILE" "$REPORT_DIR"
run_step "Day38 deploy pipeline gate" bash -lc "MIGRATION_MODE=check ./scripts/day38_deploy_pipeline_gate.sh \"$ENV_FILE\" \"$REPORT_DIR\""
run_step "Day40 monitoring tuning check" ./scripts/day40_monitoring_tuning_check.sh "$ENV_FILE" "$REPORT_DIR"
run_step "Day41 recovery gameday check" bash -lc "SCENARIO=all ./scripts/day41_gameday_recovery.sh \"$ENV_FILE\" \"$REPORT_DIR\""

run_step "Go-live meeting template exists" assert_file_exists "docs/day42-go-live-minutes-template.md"
run_step "24h monitoring plan exists" assert_file_exists "docs/day42-post-release-24h-plan.md"

echo "" >> "$REPORT_PATH"
echo "[OK] Day42 go-live decision check passed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
