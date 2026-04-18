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

LOGIN_JSON=$(curl -fsS -X POST "$API_URL/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"day7-smoke@blogsnap.local","display_name":"Day7 Smoke"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"
PROJECT_JSON=$(curl -fsS -X POST "$API_URL/v1/projects" -H "$AUTH_HEADER" -H "Content-Type: application/json" -d '{"name":"Day7 Smoke Project"}')
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

echo "\n[INFO] queue-summary"
curl -fsS "$API_URL/v1/jobs/queue-summary?project_id=$PROJECT_ID" -H "$AUTH_HEADER"

echo "\n[OK] Day7 smoke test passed"
