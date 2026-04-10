#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker compose -f docker-compose.dev.yml up -d --build postgres api worker prometheus alertmanager grafana >/tmp/day9_stack.log 2>&1 || (cat /tmp/day9_stack.log && exit 1)

for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:9090/-/healthy >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:9093/-/ready >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# generate light traffic
for _ in {1..5}; do
  curl -fsS http://127.0.0.1:8000/health >/dev/null
  curl -fsS http://127.0.0.1:8000/health/ready >/dev/null
  curl -fsS http://127.0.0.1:8000/v1/jobs/queue-summary >/dev/null
  sleep 0.2
done

echo "[INFO] Prometheus rules"
curl -fsS http://127.0.0.1:9090/api/v1/rules | python3 -c '
import json,sys
obj=json.load(sys.stdin)
groups=obj.get("data",{}).get("groups",[])
for g in groups:
    print("group=", g.get("name"))
    for r in g.get("rules",[]):
        print(" -", r.get("name"), "state=", r.get("state"))
'

echo "\n[INFO] Alertmanager ready"
curl -fsS http://127.0.0.1:9093/-/ready

echo "\n[INFO] Grafana health"
curl -fsS http://127.0.0.1:3000/api/health

echo "\n[INFO] Grafana datasources"
curl -fsS -u admin:admin http://127.0.0.1:3000/api/datasources | python3 -c '
import json,sys
arr=json.load(sys.stdin)
for d in arr:
    print("datasource=", d.get("name"), "type=", d.get("type"))
'

echo "\n[OK] Day9 observability+ demo passed"
