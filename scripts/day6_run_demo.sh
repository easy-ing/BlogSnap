#!/usr/bin/env bash
set -euo pipefail

export DATABASE_URL="postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap"

./scripts/db_reset.sh
PYTHONPATH=. python3 scripts/day6_seed_many_jobs.py

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 >/tmp/day6_api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID >/dev/null 2>&1 || true' EXIT
sleep 2

LOGIN_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"day6-demo@blogsnap.local","display_name":"Day6 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"

PROJECT_ID=$(PYTHONPATH=. python3 - << 'PY'
from sqlalchemy import select
from backend.app.db.session import SessionLocal
from backend.app.models.entities import Project, User

with SessionLocal() as db:
    user = db.scalar(select(User).where(User.email == "day6-demo@blogsnap.local"))
    project = db.scalar(select(Project).where(Project.user_id == user.id, Project.name == "Day6 Project"))
    print(project.id)
PY
)

echo "[INFO] queue-summary before"
curl -sS "http://127.0.0.1:8000/v1/jobs/queue-summary?project_id=${PROJECT_ID}" -H "$AUTH_HEADER"

echo "\n[INFO] run-batch(limit=3)"
curl -sS -X POST "http://127.0.0.1:8000/v1/jobs/run-batch?project_id=${PROJECT_ID}&limit=3" -H "$AUTH_HEADER"

echo "\n[INFO] queue-summary after batch"
curl -sS "http://127.0.0.1:8000/v1/jobs/queue-summary?project_id=${PROJECT_ID}" -H "$AUTH_HEADER"

echo "\n[INFO] run daemon (max-loops=3)"
PYTHONPATH=. python3 -m backend.app.worker.run_forever --max-loops 3

echo "[INFO] final queue-summary"
curl -sS "http://127.0.0.1:8000/v1/jobs/queue-summary?project_id=${PROJECT_ID}" -H "$AUTH_HEADER"
