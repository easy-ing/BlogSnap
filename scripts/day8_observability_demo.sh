#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker compose -f docker-compose.dev.yml up -d --build postgres api worker prometheus >/tmp/day8_stack.log 2>&1 || (cat /tmp/day8_stack.log && exit 1)

for _ in {1..60}; do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

for _ in {1..60}; do
  if curl -fsS http://127.0.0.1:9090/-/healthy >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

LOGIN_JSON=$(curl -fsS -X POST http://127.0.0.1:8000/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"day8-demo@blogsnap.local","display_name":"Day8 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"
PROJECT_JSON=$(curl -fsS -X POST http://127.0.0.1:8000/v1/projects -H "$AUTH_HEADER" -H 'Content-Type: application/json' -d '{"name":"Day8 Metrics Project"}')
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

# generate some traffic
for _ in {1..5}; do
  curl -fsS http://127.0.0.1:8000/health >/dev/null
  curl -fsS http://127.0.0.1:8000/health/ready >/dev/null
  curl -fsS "http://127.0.0.1:8000/v1/jobs/queue-summary?project_id=${PROJECT_ID}" -H "$AUTH_HEADER" >/dev/null
  sleep 0.2
done

echo "[INFO] API metrics sample"
curl -fsS http://127.0.0.1:8000/health/metrics | rg 'blogsnap_http_requests_total|blogsnap_http_request_duration_seconds|blogsnap_jobs_processed_total' | sed -n '1,20p'

echo "\n[INFO] Prometheus target health"
curl -fsS http://127.0.0.1:9090/api/v1/targets | python3 -c '
import json,sys
obj=json.load(sys.stdin)
active=obj.get("data",{}).get("activeTargets",[])
for t in active:
    labels=t.get("labels",{})
    print("job={} health={} lastError={}".format(labels.get("job"), t.get("health"), t.get("lastError","")))
'

echo "\n[OK] Day8 observability demo passed"
