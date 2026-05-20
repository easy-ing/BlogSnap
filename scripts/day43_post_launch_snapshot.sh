#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/day43-post-launch-$TS.md"

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

append_json_block() {
  local title="$1"
  local json="$2"
  {
    echo ""
    echo "## $title"
    echo '```json'
    echo "$json"
    echo '```'
  } >> "$REPORT_PATH"
}

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]]
}

health_check() {
  local out
  out="$(curl -sS http://127.0.0.1:8000/health)"
  [[ "$out" == *"ok"* ]]
}

ready_check() {
  local out
  out="$(curl -sS http://127.0.0.1:8000/health/ready)"
  [[ "$out" == *"ready"* ]]
}

echo "# Day43 Post-Launch Snapshot" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

run_step "Stack up" ./scripts/day7_run_stack.sh
run_step "Env check" ./scripts/day12_env_check.sh "$ENV_FILE"
run_step "Health endpoint check" health_check
run_step "Readiness endpoint check" ready_check
run_step "Day42 decision report exists" bash -lc 'ls -1 tmp/reports/day42-go-live-*.md >/dev/null 2>&1'
run_step "Post-release monitoring plan exists" assert_file_exists "docs/day42-post-release-24h-plan.md"
run_step "Retro template exists" assert_file_exists "docs/day43-retro-template.md"

QUEUE_JSON="$(curl -sS http://127.0.0.1:8000/v1/jobs/queue-summary)"
METRIC_HEAD="$(curl -sS http://127.0.0.1:8000/health/metrics | head -n 40)"

append_json_block "Queue Summary" "$QUEUE_JSON"
{
  echo ""
  echo "## Metrics Head (first 40 lines)"
  echo '```text'
  echo "$METRIC_HEAD"
  echo '```'
} >> "$REPORT_PATH"

echo "" >> "$REPORT_PATH"
echo "[OK] Day43 post-launch snapshot completed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
