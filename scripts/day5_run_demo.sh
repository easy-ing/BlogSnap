#!/usr/bin/env bash
set -euo pipefail

export DATABASE_URL="postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap"

# 1) Seed a draft-generation job and run worker once to create drafts.
PYTHONPATH=. python3 scripts/day4_seed_demo.py >/tmp/day5_seed.out
PYTHONPATH=. python3 -m backend.app.worker.run_once >/tmp/day5_worker_draft.out

# 2) Pick latest draft + project id
read -r DRAFT_ID PROJECT_ID <<EOF_IDS
$(PYTHONPATH=. python3 - << 'PY'
from sqlalchemy import desc, select
from backend.app.db.session import SessionLocal
from backend.app.models.entities import Draft

with SessionLocal() as db:
    draft = db.scalar(select(Draft).order_by(desc(Draft.created_at)).limit(1))
    if not draft:
        raise SystemExit("")
    print(draft.id, draft.project_id)
PY
)
EOF_IDS

if [[ -z "${DRAFT_ID:-}" || -z "${PROJECT_ID:-}" ]]; then
  echo "[ERROR] Failed to fetch draft/project id"
  exit 1
fi

# 3) Start API server
python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 >/tmp/day5_api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID >/dev/null 2>&1 || true' EXIT
sleep 2

# auth login (same seeded user ownership)
LOGIN_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"day4-demo@blogsnap.local","display_name":"Day4 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"

# 4) Select draft
curl -sS -X POST "http://127.0.0.1:8000/v1/drafts/$DRAFT_ID/select" -H "$AUTH_HEADER" >/tmp/day5_select.json

# 5) Create publish job
PAYLOAD=$(cat <<JSON
{"project_id":"$PROJECT_ID","draft_id":"$DRAFT_ID","provider":"wordpress","idempotency_key":"day5-demo-$(date +%s)"}
JSON
)
PUBLISH_JOB=$(curl -sS -X POST http://127.0.0.1:8000/v1/publish -H 'Content-Type: application/json' -H "$AUTH_HEADER" -d "$PAYLOAD")
JOB_ID=$(echo "$PUBLISH_JOB" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

# 6) Run publish job now
RUN_RESULT=$(curl -sS -X POST "http://127.0.0.1:8000/v1/jobs/$JOB_ID/run" -H "$AUTH_HEADER")
PUBLISH_ID=$(echo "$RUN_RESULT" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("result_payload",{}).get("publish_job_id",""))')

if [[ -z "${PUBLISH_ID:-}" ]]; then
  echo "[ERROR] Could not resolve publish_job_id from run result"
  echo "$RUN_RESULT"
  exit 1
fi

# 7) Fetch publish result
PUBLISH_RESULT=$(curl -sS "http://127.0.0.1:8000/v1/publish/$PUBLISH_ID" -H "$AUTH_HEADER")

echo "[OK] Publish flow completed"
echo "--- select draft ---"
cat /tmp/day5_select.json

echo "\n--- publish job created ---"
echo "$PUBLISH_JOB"

echo "\n--- job run result ---"
echo "$RUN_RESULT"

echo "\n--- publish result ---"
echo "$PUBLISH_RESULT"
