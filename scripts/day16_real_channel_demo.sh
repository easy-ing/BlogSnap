#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ALERT_LOG_DIR="$ROOT_DIR/tmp/alert-webhook"
WARN_SINK_DIR="$ROOT_DIR/tmp/webhook-sink-warning"
PD_SINK_DIR="$ROOT_DIR/tmp/pagerduty-sink"

WARN_SINK_LOG="$WARN_SINK_DIR/sink.jsonl"
PD_SINK_LOG="$PD_SINK_DIR/events.jsonl"

mkdir -p "$ALERT_LOG_DIR" "$WARN_SINK_DIR" "$PD_SINK_DIR"
: > "$ALERT_LOG_DIR/alerts.jsonl"
: > "$ALERT_LOG_DIR/forward.jsonl"
: > "$WARN_SINK_LOG"
: > "$PD_SINK_LOG"

ALERT_FORWARD_WEBHOOK_URL_WARNING=http://webhook-sink-warning:5002/ingest \
ALERT_PAGERDUTY_EVENTS_URL=http://pagerduty-sink:5005/v2/enqueue \
ALERT_PAGERDUTY_ROUTING_KEY=day16-demo-routing-key \
ALERT_PAGERDUTY_ENABLED_CHANNELS=critical \
ALERT_SILENCE_WINDOW_SECONDS=120 \
ALERT_SILENCE_WINDOW_WARNING_SECONDS=120 \
ALERT_SILENCE_WINDOW_CRITICAL_SECONDS=120 \
docker compose -f docker-compose.dev.yml up -d --build --force-recreate \
  postgres api worker prometheus alertmanager alert-webhook webhook-sink-warning pagerduty-sink \
  >/tmp/day16_stack.log 2>&1 || (cat /tmp/day16_stack.log && exit 1)

for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:9093/-/ready >/dev/null 2>&1; then break; fi
  sleep 1
done
for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:5001/ready >/dev/null 2>&1; then break; fi
  sleep 1
done
for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:5003/ready >/dev/null 2>&1 && curl -fsS http://127.0.0.1:5005/ready >/dev/null 2>&1; then break; fi
  sleep 1
done

starts_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ends_at="$(date -u -v+10M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+10 minutes" +"%Y-%m-%dT%H:%M:%SZ")"
suffix="$(date +%s)"
warning_alert="Day16Warning-${suffix}"
critical_alert="Day16Critical-${suffix}"

echo "[INFO] Send critical alert"
curl -fsS -X POST http://127.0.0.1:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d "[
    {
      \"labels\": {
        \"alertname\": \"${critical_alert}\",
        \"service\": \"worker\",
        \"severity\": \"critical\"
      },
      \"annotations\": {
        \"summary\": \"Day16 critical route to pagerduty\"
      },
      \"startsAt\": \"${starts_at}\",
      \"endsAt\": \"${ends_at}\"
    }
  ]" >/dev/null

echo "[INFO] Send duplicated critical payload directly to relay (silence check)"
curl -fsS -X POST http://127.0.0.1:5001/alerts/critical \
  -H "Content-Type: application/json" \
  -d "{
    \"receiver\": \"critical\",
    \"status\": \"firing\",
    \"alerts\": [
      {
        \"status\": \"firing\",
        \"labels\": {
          \"alertname\": \"${critical_alert}\",
          \"service\": \"worker\",
          \"severity\": \"critical\"
        },
        \"annotations\": {
          \"summary\": \"Day16 critical route to pagerduty\"
        },
        \"startsAt\": \"${starts_at}\",
        \"endsAt\": \"${ends_at}\"
      }
    ]
  }" >/dev/null

echo "[INFO] Send warning alert"
curl -fsS -X POST http://127.0.0.1:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d "[
    {
      \"labels\": {
        \"alertname\": \"${warning_alert}\",
        \"service\": \"api\",
        \"severity\": \"warning\"
      },
      \"annotations\": {
        \"summary\": \"Day16 warning route\"
      },
      \"startsAt\": \"${starts_at}\",
      \"endsAt\": \"${ends_at}\"
    }
  ]" >/dev/null

for _ in {1..40}; do
  if rg -q "${warning_alert}" "$WARN_SINK_LOG" && rg -q "${critical_alert}" "$PD_SINK_LOG"; then
    break
  fi
  sleep 1
done

if ! rg -q "${warning_alert}" "$WARN_SINK_LOG"; then
  echo "[ERROR] warning alert did not reach warning sink"
  docker compose -f docker-compose.dev.yml logs --tail=120 alertmanager alert-webhook webhook-sink-warning || true
  exit 1
fi
if ! rg -q "${critical_alert}" "$PD_SINK_LOG"; then
  echo "[ERROR] critical alert did not reach pagerduty sink"
  docker compose -f docker-compose.dev.yml logs --tail=120 alertmanager alert-webhook pagerduty-sink || true
  exit 1
fi

pd_count="$(rg -c "${critical_alert}" "$PD_SINK_LOG" || true)"
if [[ "${pd_count}" -gt 1 ]]; then
  echo "[ERROR] duplicate pagerduty events detected: ${pd_count}"
  exit 1
fi

echo "[INFO] Relay stats"
stats_json="$(curl -fsS http://127.0.0.1:5001/stats)"
echo "$stats_json" | python3 -m json.tool

silenced_count="$(echo "$stats_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["stats"].get("silence_skipped_critical_total",0))')"
if [[ "${silenced_count}" -lt 1 ]]; then
  echo "[ERROR] expected silenced critical duplicate >= 1, got ${silenced_count}"
  exit 1
fi

echo "[OK] Day16 real-channel relay demo passed"
