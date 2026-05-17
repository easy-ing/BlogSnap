#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env.example}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/monitoring-tuning-$TS.md"

RULES_FILE="monitoring/rules/blogsnap-alerts.yml"
ALERTMANAGER_FILE="monitoring/alertmanager/alertmanager.yml"

read_env_key() {
  local key="$1"
  if command -v rg >/dev/null 2>&1; then
    rg "^${key}=" "$ENV_FILE" | tail -n1 | cut -d'=' -f2- || true
  else
    grep "^${key}=" "$ENV_FILE" | tail -n1 | cut -d'=' -f2- || true
  fi
}

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

assert_contains() {
  local path="$1"
  local pattern="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$path"
  else
    grep -qE "$pattern" "$path"
  fi
}

assert_positive_int_env() {
  local key="$1"
  local value
  value="$(read_env_key "$key")"
  [[ "$value" =~ ^[0-9]+$ ]] && [[ "$value" -gt 0 ]]
}

echo "# Day40 Monitoring Tuning Check" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

run_step "Env sanity check" ./scripts/day12_env_check.sh "$ENV_FILE"

run_step "Rules file exists" assert_file_exists "$RULES_FILE"
run_step "Alertmanager config exists" assert_file_exists "$ALERTMANAGER_FILE"

run_step "Rule includes API error rate alert" assert_contains "$RULES_FILE" "alert: BlogSnapAPIHighErrorRate"
run_step "Rule includes API latency alert" assert_contains "$RULES_FILE" "alert: BlogSnapAPISlowP95"
run_step "Rule includes worker failure alert" assert_contains "$RULES_FILE" "alert: BlogSnapJobsFailing"

run_step "Alert route has warning receiver" assert_contains "$ALERTMANAGER_FILE" "receiver: warning"
run_step "Alert route has critical receiver" assert_contains "$ALERTMANAGER_FILE" "receiver: critical"
run_step "Inhibit rule exists" assert_contains "$ALERTMANAGER_FILE" "inhibit_rules:"

run_step "Silence window default positive" assert_positive_int_env "ALERT_SILENCE_WINDOW_SECONDS"
run_step "Silence warning window positive" assert_positive_int_env "ALERT_SILENCE_WINDOW_WARNING_SECONDS"
run_step "Silence critical window positive" assert_positive_int_env "ALERT_SILENCE_WINDOW_CRITICAL_SECONDS"

echo "" >> "$REPORT_PATH"
echo "[OK] Day40 monitoring tuning check passed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
