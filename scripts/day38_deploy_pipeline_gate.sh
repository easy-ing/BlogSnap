#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
MIGRATION_MODE="${MIGRATION_MODE:-check}"

mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/deploy-pipeline-gate-$TS.md"

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

run_migration_gate() {
  if [[ "$MIGRATION_MODE" == "check" ]]; then
    ./scripts/db_verify_schema.sh
  elif [[ "$MIGRATION_MODE" == "apply" ]]; then
    ./scripts/db_apply_migration.sh
    ./scripts/db_verify_schema.sh
  else
    echo "[ERROR] invalid MIGRATION_MODE: $MIGRATION_MODE (allowed: check|apply)"
    return 1
  fi
}

echo "# Deploy Pipeline Gate Report" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "- migration_mode: $MIGRATION_MODE" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

echo "[INFO] start deploy pipeline gate"
run_step "Release decision gate" ./scripts/day37_release_decision_gate.sh tmp/reports
run_step "Environment validation" ./scripts/day12_env_check.sh "$ENV_FILE"
run_step "CI suite" ./scripts/day14_ci_suite.sh
run_step "Migration gate ($MIGRATION_MODE)" run_migration_gate
run_step "Go-live check" ./scripts/day15_go_live_check.sh "$ENV_FILE"

echo "" >> "$REPORT_PATH"
echo "[OK] deploy pipeline gate passed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
