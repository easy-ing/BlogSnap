#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

docker compose -f docker-compose.dev.yml up -d --build postgres api worker

"$ROOT_DIR/scripts/day7_smoke_test.sh"

echo "[INFO] Stack is running: postgres, api, worker"
echo "[INFO] Use 'docker compose -f docker-compose.dev.yml logs -f api worker' to monitor"
