#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
SCENARIO="${SCENARIO:-all}" # all | db | queue | provider
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/day41-gameday-$TS.md"

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

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]]
}

scenario_db() {
  echo "[INFO] scenario=db: verify schema + readiness path"
  ./scripts/db_verify_schema.sh
  local ready
  ready="$(curl -sS http://127.0.0.1:8000/health/ready || true)"
  assert_contains "$ready" "ready"
}

scenario_queue() {
  echo "[INFO] scenario=queue: run queue summary and one publish flow"
  local summary publish
  summary="$(curl -sS http://127.0.0.1:8000/v1/jobs/queue-summary || true)"
  assert_contains "$summary" "pending"

  publish="$(./scripts/day5_run_demo.sh 2>&1 || true)"
  assert_contains "$publish" "[OK] Publish flow completed"
}

scenario_provider() {
  echo "[INFO] scenario=provider: safe rehearsal in dry-run mode"
  REHEARSAL_MODE=dry-run ./scripts/day39_provider_rehearsal.sh "$ENV_FILE" "$REPORT_DIR"
}

echo "# Day41 Gameday Recovery Report" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "- scenario: $SCENARIO" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

run_step "Env sanity check" ./scripts/day12_env_check.sh "$ENV_FILE"
run_step "Runtime stack up" ./scripts/day7_run_stack.sh

case "$SCENARIO" in
  all)
    run_step "DB recovery scenario" scenario_db
    run_step "Queue recovery scenario" scenario_queue
    run_step "Provider recovery scenario" scenario_provider
    ;;
  db)
    run_step "DB recovery scenario" scenario_db
    ;;
  queue)
    run_step "Queue recovery scenario" scenario_queue
    ;;
  provider)
    run_step "Provider recovery scenario" scenario_provider
    ;;
  *)
    echo "[ERROR] invalid SCENARIO: $SCENARIO"
    exit 1
    ;;
esac

echo "" >> "$REPORT_PATH"
echo "[OK] Day41 gameday recovery check passed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
