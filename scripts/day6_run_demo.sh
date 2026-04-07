#!/usr/bin/env bash
set -euo pipefail

export DATABASE_URL="postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap"

./scripts/db_reset.sh
PYTHONPATH=. python3 scripts/day6_seed_many_jobs.py

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 >/tmp/day6_api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID >/dev/null 2>&1 || true' EXIT
sleep 2

echo "[INFO] queue-summary before"
curl -sS http://127.0.0.1:8000/v1/jobs/queue-summary

echo "\n[INFO] run-batch(limit=3)"
curl -sS -X POST 'http://127.0.0.1:8000/v1/jobs/run-batch?limit=3'

echo "\n[INFO] queue-summary after batch"
curl -sS http://127.0.0.1:8000/v1/jobs/queue-summary

echo "\n[INFO] run daemon (max-loops=3)"
PYTHONPATH=. python3 -m backend.app.worker.run_forever --max-loops 3

echo "[INFO] final queue-summary"
curl -sS http://127.0.0.1:8000/v1/jobs/queue-summary
