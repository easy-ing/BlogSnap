#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ALERT_LOG_DIR="$ROOT_DIR/tmp/alert-webhook"
SINK_LOG_DIR="$ROOT_DIR/tmp/webhook-sink"
ALERT_LOG_FILE="$ALERT_LOG_DIR/alerts.jsonl"
FORWARD_LOG_FILE="$ALERT_LOG_DIR/forward.jsonl"
SINK_LOG_FILE="$SINK_LOG_DIR/sink.jsonl"

mkdir -p "$ALERT_LOG_DIR" "$SINK_LOG_DIR"
: > "$ALERT_LOG_FILE"
: > "$FORWARD_LOG_FILE"
: > "$SINK_LOG_FILE"

ALERT_FORWARD_WEBHOOK_URL=http://webhook-sink:5002/ingest \
docker compose -f docker-compose.dev.yml up -d --build --force-recreate \
  postgres api worker prometheus webhook-sink alert-webhook alertmanager grafana \
  >/tmp/day11_stack.log 2>&1 || (cat /tmp/day11_stack.log && exit 1)

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
for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:5002/ready >/dev/null 2>&1; then
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
        \"alertname\": \"Day11SyntheticCritical\",
        \"service\": \"worker\",
        \"severity\": \"critical\"
      },
      \"annotations\": {
        \"summary\": \"Day11 synthetic alert\",
        \"description\": \"Validate alert webhook relay forwarding\"
      },
      \"startsAt\": \"${starts_at}\",
      \"endsAt\": \"${ends_at}\"
    }
  ]" >/dev/null

echo "[INFO] Wait until mock sink receives forwarded message"
for _ in {1..40}; do
  if rg -q "Day11SyntheticCritical" "$SINK_LOG_FILE"; then
    break
  fi
  sleep 1
done

if ! rg -q "Day11SyntheticCritical" "$SINK_LOG_FILE"; then
  echo "[ERROR] Forwarded alert was not delivered to sink: $SINK_LOG_FILE"
  docker compose -f docker-compose.dev.yml logs --tail=120 alertmanager alert-webhook webhook-sink || true
  exit 1
fi

echo "[INFO] Relay stats"
curl -fsS http://127.0.0.1:5001/stats | python3 -m json.tool

echo "[INFO] Forwarded payload sample"
tail -n 1 "$SINK_LOG_FILE" | python3 -c '
import json,sys
line=sys.stdin.read().strip()
obj=json.loads(line)
text=obj.get("payload",{}).get("text","")
print(text)
'

echo "[OK] Day11 webhook relay demo passed"
