#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap}"
API_PORT="${API_PORT:-8021}"
BASE_URL="http://127.0.0.1:${API_PORT}"

./scripts/db_reset.sh >/tmp/day21_db_reset.log 2>&1 || (cat /tmp/day21_db_reset.log && exit 1)

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port "$API_PORT" >/tmp/day21_api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID >/dev/null 2>&1 || true' EXIT

for _ in {1..60}; do
  if curl -fsS "${BASE_URL}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

LOGIN_JSON=$(curl -sS -X POST "${BASE_URL}/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"day21-demo@blogsnap.local","display_name":"Day21 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"

PROJECT_JSON=$(curl -sS -X POST "${BASE_URL}/v1/projects" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d '{"name":"Day21 Scheduling Control"}')
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

GEN_JSON=$(curl -sS -X POST "${BASE_URL}/v1/drafts/generate" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"post_type\":\"explanation\",\"keyword\":\"Day21 예약 제어\",\"sentiment\":1,\"draft_count\":2}")
GEN_JOB_ID=$(echo "$GEN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
curl -sS -X POST "${BASE_URL}/v1/jobs/$GEN_JOB_ID/run" -H "$AUTH_HEADER" >/tmp/day21_gen_run.json

DRAFT_ID=$(curl -sS "${BASE_URL}/v1/drafts?project_id=$PROJECT_ID" -H "$AUTH_HEADER" | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')
curl -sS -X POST "${BASE_URL}/v1/drafts/$DRAFT_ID/select" -H "$AUTH_HEADER" >/tmp/day21_select.json

FUTURE_AT=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat())
PY
)

# Scenario A: schedule update -> immediate run
CREATE_A=$(curl -sS -X POST "${BASE_URL}/v1/publish" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"draft_id\":\"$DRAFT_ID\",\"provider\":\"wordpress\",\"publish_at\":\"$FUTURE_AT\",\"idempotency_key\":\"day21-a-$(date +%s)\"}")
JOB_A=$(echo "$CREATE_A" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
PUB_A=$(echo "$CREATE_A" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("result_payload",{}).get("publish_job_id",""))')

PATCH_A=$(curl -sS -X PATCH "${BASE_URL}/v1/publish/$PUB_A/schedule" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d '{"publish_at": null}')
PATCH_STATUS=$(echo "$PATCH_A" | python3 -c 'import sys,json; print(json.load(sys.stdin)["schedule_status"])')
if [[ "$PATCH_STATUS" != "READY" ]]; then
  echo "[ERROR] expected READY after schedule patch, got: $PATCH_STATUS"
  echo "$PATCH_A"
  exit 1
fi

RUN_A=$(curl -sS -X POST "${BASE_URL}/v1/jobs/$JOB_A/run" -H "$AUTH_HEADER")
RUN_A_STATUS=$(echo "$RUN_A" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')
if [[ "$RUN_A_STATUS" != "SUCCEEDED" ]]; then
  echo "[ERROR] expected SUCCEEDED after schedule to now, got: $RUN_A_STATUS"
  echo "$RUN_A"
  exit 1
fi

# Scenario B: schedule cancel -> blocked
CREATE_B=$(curl -sS -X POST "${BASE_URL}/v1/publish" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"draft_id\":\"$DRAFT_ID\",\"provider\":\"wordpress\",\"publish_at\":\"$FUTURE_AT\",\"idempotency_key\":\"day21-b-$(date +%s)\"}")
JOB_B=$(echo "$CREATE_B" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
PUB_B=$(echo "$CREATE_B" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("result_payload",{}).get("publish_job_id",""))')

CANCEL_B=$(curl -sS -X POST "${BASE_URL}/v1/publish/$PUB_B/cancel" -H "$AUTH_HEADER")
CANCEL_STATUS=$(echo "$CANCEL_B" | python3 -c 'import sys,json; print(json.load(sys.stdin)["schedule_status"])')
if [[ "$CANCEL_STATUS" != "CANCELLED" ]]; then
  echo "[ERROR] expected CANCELLED after cancel, got: $CANCEL_STATUS"
  echo "$CANCEL_B"
  exit 1
fi

RUN_B=$(curl -sS -X POST "${BASE_URL}/v1/jobs/$JOB_B/run" -H "$AUTH_HEADER")
RUN_B_STATUS=$(echo "$RUN_B" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')
if [[ "$RUN_B_STATUS" != "FAILED" ]]; then
  echo "[ERROR] cancelled publish job should be FAILED, got: $RUN_B_STATUS"
  echo "$RUN_B"
  exit 1
fi

echo "[OK] Day21 scheduling controls demo passed"
