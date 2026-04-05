#!/usr/bin/env bash
set -euo pipefail

export DATABASE_URL="postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap"

PYTHONPATH=. python3 scripts/day4_seed_demo.py
PYTHONPATH=. python3 -m backend.app.worker.run_once

echo "[INFO] Recent jobs"
docker exec -i blogsnap-postgres psql -U blogsnap -d blogsnap -c "select id, type, status, attempt_count, created_at from jobs order by created_at desc limit 5;"

echo "[INFO] Recent drafts"
docker exec -i blogsnap-postgres psql -U blogsnap -d blogsnap -c "select id, title, keyword, version_no, variant_no, status, created_at from drafts order by created_at desc limit 5;"
