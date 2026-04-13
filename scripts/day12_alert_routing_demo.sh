#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ALERT_LOG_DIR="$ROOT_DIR/tmp/alert-webhook"
WARN_SINK_DIR="$ROOT_DIR/tmp/webhook-sink-warning"
CRIT_SINK_DIR="$ROOT_DIR/tmp/webhook-sink-critical"
WARN_SINK_LOG="$WARN_SINK_DIR/sink.jsonl"
CRIT_SINK_LOG="$CRIT_SINK_DIR/sink.jsonl"

mkdir -p "$ALERT_LOG_DIR" "$WARN_SINK_DIR" "$CRIT_SINK_DIR"
: > "$ALERT_LOG_DIR/alerts.jsonl"
: > "$ALERT_LOG_DIR/forward.jsonl"
: > "$WARN_SINK_LOG"
: > "$CRIT_SINK_LOG"

ALERT_FORWARD_WEBHOOK_URL_WARNING=http://webhook-sink-warning:5002/ingest \
ALERT_FORWARD_WEBHOOK_URL_CRITICAL=http://webhook-sink-critical:5002/ingest \
docker compose -f docker-compose.dev.yml up -d --build --force-recreate \
  postgres api worker prometheus alertmanager alert-webhook webhook-sink-warning webhook-sink-critical grafana \
  >/tmp/day12_stack.log 2>&1 || (cat /tmp/day12_stack.log && exit 1)

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
  if curl -fsS http://127.0.0.1:5003/ready >/dev/null 2>&1 && curl -fsS http://127.0.0.1:5004/ready >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

starts_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ends_at="$(date -u -v+15M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+15 minutes" +"%Y-%m-%dT%H:%M:%SZ")"

echo "[INFO] Send warning + critical synthetic alerts"
curl -fsS -X POST http://127.0.0.1:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d "[
    {
      \"labels\": {
        \"alertname\": \"Day12WarningSynthetic\",
        \"service\": \"api\",
        \"severity\": \"warning\"
      },
      \"annotations\": {
        \"summary\": \"Day12 warning route test\"
      },
      \"startsAt\": \"${starts_at}\",
      \"endsAt\": \"${ends_at}\"
    },
    {
      \"labels\": {
        \"alertname\": \"Day12CriticalSynthetic\",
        \"service\": \"worker\",
        \"severity\": \"critical\"
      },
      \"annotations\": {
        \"summary\": \"Day12 critical route test\"
      },
      \"startsAt\": \"${starts_at}\",
      \"endsAt\": \"${ends_at}\"
    }
  ]" >/dev/null

echo "[INFO] Wait for routed delivery"
for _ in {1..40}; do
  if rg -q "Day12WarningSynthetic" "$WARN_SINK_LOG" && rg -q "Day12CriticalSynthetic" "$CRIT_SINK_LOG"; then
    break
  fi
  sleep 1
done

if ! rg -q "Day12WarningSynthetic" "$WARN_SINK_LOG"; then
  echo "[ERROR] warning alert did not reach warning sink"
  docker compose -f docker-compose.dev.yml logs --tail=120 alertmanager alert-webhook webhook-sink-warning || true
  exit 1
fi
if ! rg -q "Day12CriticalSynthetic" "$CRIT_SINK_LOG"; then
  echo "[ERROR] critical alert did not reach critical sink"
  docker compose -f docker-compose.dev.yml logs --tail=120 alertmanager alert-webhook webhook-sink-critical || true
  exit 1
fi

echo "[INFO] Relay stats"
curl -fsS http://127.0.0.1:5001/stats | python3 -m json.tool

echo "[OK] Day12 alert routing demo passed"
