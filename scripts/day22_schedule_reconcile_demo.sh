#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap}"
API_PORT="${API_PORT:-8022}"
BASE_URL="http://127.0.0.1:${API_PORT}"

./scripts/db_reset.sh >/tmp/day22_db_reset.log 2>&1 || (cat /tmp/day22_db_reset.log && exit 1)

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port "$API_PORT" >/tmp/day22_api.log 2>&1 &
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
  -d '{"email":"day22-demo@blogsnap.local","display_name":"Day22 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"

PROJECT_JSON=$(curl -sS -X POST "${BASE_URL}/v1/projects" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d '{"name":"Day22 Reconcile Demo"}')
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

GEN_JSON=$(curl -sS -X POST "${BASE_URL}/v1/drafts/generate" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"post_type\":\"explanation\",\"keyword\":\"Day22 Reconcile\",\"sentiment\":1,\"draft_count\":2}")
GEN_JOB_ID=$(echo "$GEN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
curl -sS -X POST "${BASE_URL}/v1/jobs/$GEN_JOB_ID/run" -H "$AUTH_HEADER" >/tmp/day22_gen_run.json

DRAFT_ID=$(curl -sS "${BASE_URL}/v1/drafts?project_id=$PROJECT_ID" -H "$AUTH_HEADER" | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')
curl -sS -X POST "${BASE_URL}/v1/drafts/$DRAFT_ID/select" -H "$AUTH_HEADER" >/tmp/day22_select.json

FUTURE_AT=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat())
PY
)

CREATE_JSON=$(curl -sS -X POST "${BASE_URL}/v1/publish" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"draft_id\":\"$DRAFT_ID\",\"provider\":\"wordpress\",\"publish_at\":\"$FUTURE_AT\",\"idempotency_key\":\"day22-$(date +%s)\"}")
JOB_ID=$(echo "$CREATE_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
PUBLISH_JOB_ID=$(echo "$CREATE_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("result_payload",{}).get("publish_job_id",""))')

RECON1=$(curl -sS -X POST "${BASE_URL}/v1/jobs/reconcile-schedules?project_id=$PROJECT_ID" -H "$AUTH_HEADER")
WAITING1=$(echo "$RECON1" | python3 -c 'import sys,json; print(json.load(sys.stdin)["waiting"])')
if [[ "$WAITING1" -lt 1 ]]; then
  echo "[ERROR] expected waiting >= 1 on first reconcile"
  echo "$RECON1"
  exit 1
fi

# Move schedule near-future, then let reconciler activate it.
NEAR_FUTURE=$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(seconds=2)).isoformat())
PY
)
PATCH_JSON=$(curl -sS -X PATCH "${BASE_URL}/v1/publish/$PUBLISH_JOB_ID/schedule" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"publish_at\":\"$NEAR_FUTURE\"}")
PATCH_STATUS=$(echo "$PATCH_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["schedule_status"])')
if [[ "$PATCH_STATUS" != "SCHEDULED" ]]; then
  echo "[ERROR] expected SCHEDULED after near-future patch"
  echo "$PATCH_JSON"
  exit 1
fi

sleep 3

RECON2=$(curl -sS -X POST "${BASE_URL}/v1/jobs/reconcile-schedules?project_id=$PROJECT_ID" -H "$AUTH_HEADER")
ACTIVATED2=$(echo "$RECON2" | python3 -c 'import sys,json; print(json.load(sys.stdin)["activated"])')
if [[ "$ACTIVATED2" -lt 1 ]]; then
  echo "[ERROR] expected activated >= 1 after due schedule"
  echo "$RECON2"
  exit 1
fi

RUN_JSON=$(curl -sS -X POST "${BASE_URL}/v1/jobs/$JOB_ID/run" -H "$AUTH_HEADER")
RUN_STATUS=$(echo "$RUN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')
if [[ "$RUN_STATUS" != "SUCCEEDED" ]]; then
  echo "[ERROR] expected SUCCEEDED after reconcile activation, got: $RUN_STATUS"
  echo "$RUN_JSON"
  exit 1
fi

echo "[OK] Day22 schedule reconcile demo passed"
