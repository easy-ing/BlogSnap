#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env}"
RUN_REAL_PUBLISH="${RUN_REAL_PUBLISH:-no}"

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
  rg "^${key}=" "$ENV_FILE" | tail -n1 | cut -d'=' -f2- || true
}

publish_mode="$(read_env_key WORKER_PUBLISH_MODE | tr '[:upper:]' '[:lower:]')"
if [[ -z "$publish_mode" ]]; then
  publish_mode="mock"
fi

echo "[STEP 1/5] Env sanity check"
./scripts/day12_env_check.sh "$ENV_FILE"

echo "[STEP 2/5] Release readiness gates"
./scripts/day15_release_readiness.sh

echo "[STEP 3/5] Runtime stack smoke"
./scripts/day7_run_stack.sh

echo "[STEP 4/5] Alert routing check"
./scripts/day12_alert_routing_demo.sh

echo "[STEP 5/5] Publish flow check (mode=$publish_mode)"
if [[ "$publish_mode" == "wordpress" && "$RUN_REAL_PUBLISH" != "yes" ]]; then
  echo "[WARN] WORKER_PUBLISH_MODE=wordpress but RUN_REAL_PUBLISH!=yes"
  echo "[WARN] real publish check skipped to avoid accidental posting"
  echo "[INFO] Run with: RUN_REAL_PUBLISH=yes ./scripts/day15_go_live_check.sh $ENV_FILE"
else
  ./scripts/day5_run_demo.sh
fi

echo "[OK] Day15 go-live one-shot check completed"
