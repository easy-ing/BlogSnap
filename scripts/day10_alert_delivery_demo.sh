#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ALERT_LOG_DIR="$ROOT_DIR/tmp/alert-webhook"
ALERT_LOG_FILE="$ALERT_LOG_DIR/alerts.jsonl"
mkdir -p "$ALERT_LOG_DIR"
: > "$ALERT_LOG_FILE"

docker compose -f docker-compose.dev.yml up -d --build \
  --force-recreate \
  postgres api worker prometheus alert-webhook alertmanager grafana \
  >/tmp/day10_stack.log 2>&1 || (cat /tmp/day10_stack.log && exit 1)

for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:9093/-/ready >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:5001/ready >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

starts_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ends_at="$(date -u -v+15M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+15 minutes" +"%Y-%m-%dT%H:%M:%SZ")"

echo "[INFO] Send synthetic alert to Alertmanager"
curl -fsS -X POST http://127.0.0.1:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d "[
    {
      \"labels\": {
        \"alertname\": \"Day10SyntheticCritical\",
        \"service\": \"api\",
        \"severity\": \"critical\"
      },
      \"annotations\": {
        \"summary\": \"Day10 synthetic critical alert\",
        \"description\": \"Used for local webhook delivery validation\"
      },
      \"startsAt\": \"${starts_at}\",
      \"endsAt\": \"${ends_at}\"
    }
  ]" >/dev/null

echo "[INFO] Wait until webhook receives the alert"
for _ in {1..40}; do
  if rg -q "Day10SyntheticCritical" "$ALERT_LOG_FILE"; then
    break
  fi
  sleep 1
done

if ! rg -q "Day10SyntheticCritical" "$ALERT_LOG_FILE"; then
  echo "[ERROR] Alert was not delivered to webhook log: $ALERT_LOG_FILE"
  docker compose -f docker-compose.dev.yml logs --tail=80 alertmanager alert-webhook || true
  exit 1
fi

echo "[INFO] Received alert payload sample"
tail -n 1 "$ALERT_LOG_FILE" | python3 -c '
import json,sys
line=sys.stdin.read().strip()
obj=json.loads(line)
alerts=obj.get("payload",{}).get("alerts",[])
for a in alerts:
    print("alertname=", a.get("labels",{}).get("alertname"), "status=", a.get("status"))
'

echo "[OK] Day10 alert delivery demo passed"
