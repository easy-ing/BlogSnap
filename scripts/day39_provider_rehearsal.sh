#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env}"
REHEARSAL_MODE="${REHEARSAL_MODE:-dry-run}" # dry-run | real-run
PROVIDERS="${PROVIDERS:-wordpress,tistory}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/provider-rehearsal-$TS.md"

if [[ ! -f "$ENV_FILE" ]]; then
  if [[ "$ENV_FILE" == ".env" && -f ".env.example" ]]; then
    ENV_FILE=".env.example"
    echo "[WARN] .env not found. fallback to .env.example"
  else
    echo "[ERROR] env file not found: $ENV_FILE"
    exit 1
  fi
fi

read_env_key() {
  local key="$1"
  if command -v rg >/dev/null 2>&1; then
    rg "^${key}=" "$ENV_FILE" | tail -n1 | cut -d'=' -f2- || true
  else
    grep "^${key}=" "$ENV_FILE" | tail -n1 | cut -d'=' -f2- || true
  fi
}

assert_nonempty() {
  local key="$1"
  local val
  val="$(read_env_key "$key")"
  if [[ -z "$val" ]]; then
    echo "[ERROR] missing required key: $key"
    exit 1
  fi
}

assert_not_placeholder() {
  local key="$1"
  local val
  val="$(read_env_key "$key")"
  if [[ -z "$val" ]]; then
    echo "[ERROR] missing required key: $key"
    exit 1
  fi
  if [[ "$val" == *"your_"* || "$val" == *"xxxx"* || "$val" == *"change-me"* || "$val" == "sk-..." ]]; then
    echo "[ERROR] placeholder detected for key: $key"
    exit 1
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

check_provider_keys() {
  local provider="$1"
  if [[ "$provider" == "wordpress" ]]; then
    if [[ "$REHEARSAL_MODE" == "real-run" ]]; then
      assert_not_placeholder "WORDPRESS_BASE_URL"
      assert_not_placeholder "WORDPRESS_USERNAME"
      assert_not_placeholder "WORDPRESS_APP_PASSWORD"
    else
      assert_nonempty "WORDPRESS_BASE_URL"
      assert_nonempty "WORDPRESS_USERNAME"
      assert_nonempty "WORDPRESS_APP_PASSWORD"
    fi
  elif [[ "$provider" == "tistory" ]]; then
    if [[ "$REHEARSAL_MODE" == "real-run" ]]; then
      assert_not_placeholder "TISTORY_API_URL"
      assert_not_placeholder "TISTORY_ACCESS_TOKEN"
      assert_not_placeholder "TISTORY_BLOG_NAME"
    else
      assert_nonempty "TISTORY_API_URL"
      assert_nonempty "TISTORY_ACCESS_TOKEN"
      assert_nonempty "TISTORY_BLOG_NAME"
    fi
  else
    echo "[ERROR] unsupported provider: $provider"
    return 1
  fi
}

echo "# Day39 Provider Rehearsal Report" > "$REPORT_PATH"
echo "" >> "$REPORT_PATH"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_PATH"
echo "- env_file: $ENV_FILE" >> "$REPORT_PATH"
echo "- rehearsal_mode: $REHEARSAL_MODE" >> "$REPORT_PATH"
echo "- providers: $PROVIDERS" >> "$REPORT_PATH"
echo "" >> "$REPORT_PATH"

run_step "Global env check" ./scripts/day12_env_check.sh "$ENV_FILE"

IFS=',' read -r -a provider_list <<< "$PROVIDERS"
for provider in "${provider_list[@]}"; do
  provider="$(echo "$provider" | tr '[:upper:]' '[:lower:]' | xargs)"
  run_step "Provider key check ($provider)" check_provider_keys "$provider"
done

if [[ "$REHEARSAL_MODE" == "dry-run" ]]; then
  run_step "Mock publish flow rehearsal" ./scripts/day19_multi_provider_demo.sh
else
  run_step "Safety confirmation" bash -lc '[[ "${RUN_REAL_PUBLISH:-no}" == "yes" ]]'
  for provider in "${provider_list[@]}"; do
    provider="$(echo "$provider" | tr '[:upper:]' '[:lower:]' | xargs)"
    echo "[INFO] running real publish rehearsal for provider=$provider"
    WORKER_PUBLISH_MODE="$provider" RUN_REAL_PUBLISH="yes" run_step \
      "Real publish rehearsal ($provider)" \
      ./scripts/day5_run_demo.sh
  done
fi

echo "" >> "$REPORT_PATH"
echo "[OK] Day39 provider rehearsal passed" | tee -a "$REPORT_PATH"
echo "[INFO] report: $REPORT_PATH"
