#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$ROOT_DIR/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] env file not found: $ENV_FILE"
  exit 1
fi

echo "[INFO] checking env file: $ENV_FILE"

missing=0
warn=0

require_key() {
  local key="$1"
  if ! rg -q "^${key}=" "$ENV_FILE"; then
    echo "[ERROR] missing key: ${key}"
    missing=1
  fi
}

read_key() {
  local key="$1"
  rg "^${key}=" "$ENV_FILE" | tail -n1 | cut -d'=' -f2-
}

require_key "OPENAI_API_KEY"
require_key "DATABASE_URL"
require_key "WORKER_PUBLISH_MODE"
require_key "ALERT_FORWARD_TIMEOUT_SECONDS"

openai_key="$(read_key OPENAI_API_KEY || true)"
if [[ -z "$openai_key" || "$openai_key" == "sk-..." ]]; then
  echo "[WARN] OPENAI_API_KEY looks like placeholder"
  warn=1
fi

publish_mode="$(read_key WORKER_PUBLISH_MODE || true)"
if [[ "$publish_mode" == "wordpress" ]]; then
  for key in WORDPRESS_BASE_URL WORDPRESS_USERNAME WORDPRESS_APP_PASSWORD; do
    require_key "$key"
    value="$(read_key "$key" || true)"
    if [[ -z "$value" || "$value" == *"yourblog.com"* || "$value" == *"your_username"* || "$value" == *"xxxx"* ]]; then
      echo "[WARN] ${key} looks like placeholder"
      warn=1
    fi
  done
fi

warn_url="$(read_key ALERT_FORWARD_WEBHOOK_URL_WARNING || true)"
crit_url="$(read_key ALERT_FORWARD_WEBHOOK_URL_CRITICAL || true)"
generic_url="$(read_key ALERT_FORWARD_WEBHOOK_URL || true)"

if [[ -z "$warn_url" && -z "$crit_url" && -z "$generic_url" ]]; then
  echo "[WARN] no alert forward webhook configured (ALERT_FORWARD_WEBHOOK_URL[_WARNING|_CRITICAL])"
  warn=1
fi

if [[ "$missing" -ne 0 ]]; then
  echo "[FAIL] required env keys missing"
  exit 1
fi

if [[ "$warn" -ne 0 ]]; then
  echo "[OK with warnings] env check completed"
  exit 0
fi

echo "[OK] env check completed"
