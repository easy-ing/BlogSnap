#!/usr/bin/env bash
set -euo pipefail

API_URL=${API_URL:-http://127.0.0.1:8000}

for i in {1..60}; do
  if curl -fsS "$API_URL/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "[INFO] health"
curl -fsS "$API_URL/health"

echo "\n[INFO] readiness"
curl -fsS "$API_URL/health/ready"

echo "\n[INFO] queue-summary"
curl -fsS "$API_URL/v1/jobs/queue-summary"

echo "\n[OK] Day7 smoke test passed"
