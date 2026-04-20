#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export DATABASE_URL="postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap"

./scripts/db_reset.sh >/tmp/day18_db_reset.log 2>&1 || (cat /tmp/day18_db_reset.log && exit 1)

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 >/tmp/day18_api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID >/dev/null 2>&1 || true' EXIT
sleep 2

LOGIN_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"day18-demo@blogsnap.local","display_name":"Day18 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"

PROJECT_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/projects \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d '{"name":"Day18 Scheduled Project"}')
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

GEN_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/drafts/generate \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"post_type\":\"explanation\",\"keyword\":\"Day18 예약 발행\",\"sentiment\":1,\"draft_count\":2}")
GEN_JOB_ID=$(echo "$GEN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
curl -sS -X POST "http://127.0.0.1:8000/v1/jobs/$GEN_JOB_ID/run" -H "$AUTH_HEADER" >/tmp/day18_gen_run.json

DRAFT_ID=$(curl -sS "http://127.0.0.1:8000/v1/drafts?project_id=$PROJECT_ID" -H "$AUTH_HEADER" | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')
curl -sS -X POST "http://127.0.0.1:8000/v1/drafts/$DRAFT_ID/select" -H "$AUTH_HEADER" >/tmp/day18_select.json

PUBLISH_AT=$(python3 - << 'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(seconds=12)).isoformat())
PY
)

PUBLISH_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/publish \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"draft_id\":\"$DRAFT_ID\",\"provider\":\"wordpress\",\"publish_at\":\"$PUBLISH_AT\",\"idempotency_key\":\"day18-$(date +%s)\"}")
JOB_ID=$(echo "$PUBLISH_JSON" | python3 -c 'import sys,json; o=json.load(sys.stdin); print(o["id"]); print(o["status"]); print(o.get("next_retry_at"))' | sed -n '1p')
INITIAL_STATUS=$(echo "$PUBLISH_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')

if [[ "$INITIAL_STATUS" != "RETRYING" ]]; then
  echo "[ERROR] expected initial publish job status RETRYING, got: $INITIAL_STATUS"
  echo "$PUBLISH_JSON"
  exit 1
fi

EARLY_JSON=$(curl -sS -X POST "http://127.0.0.1:8000/v1/jobs/$JOB_ID/run" -H "$AUTH_HEADER")
EARLY_STATUS=$(echo "$EARLY_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')
if [[ "$EARLY_STATUS" != "RETRYING" ]]; then
  echo "[ERROR] early run should keep RETRYING, got: $EARLY_STATUS"
  echo "$EARLY_JSON"
  exit 1
fi

echo "[INFO] waiting for scheduled time..."
sleep 13

FINAL_JSON=$(curl -sS -X POST "http://127.0.0.1:8000/v1/jobs/$JOB_ID/run" -H "$AUTH_HEADER")
FINAL_STATUS=$(echo "$FINAL_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')
if [[ "$FINAL_STATUS" != "SUCCEEDED" ]]; then
  echo "[ERROR] scheduled run should succeed after publish_at, got: $FINAL_STATUS"
  echo "$FINAL_JSON"
  exit 1
fi

PUBLISH_ID=$(echo "$FINAL_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("result_payload",{}).get("publish_job_id",""))')
PUBLISH_RESULT=$(curl -sS "http://127.0.0.1:8000/v1/publish/$PUBLISH_ID" -H "$AUTH_HEADER")
PUBLISH_STATUS=$(echo "$PUBLISH_RESULT" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')
if [[ "$PUBLISH_STATUS" != "PUBLISHED" ]]; then
  echo "[ERROR] publish result should be PUBLISHED, got: $PUBLISH_STATUS"
  echo "$PUBLISH_RESULT"
  exit 1
fi

echo "[OK] Day18 scheduled publish demo passed"
