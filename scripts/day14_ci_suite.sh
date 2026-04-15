#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap}"
export DATABASE_URL

echo "[INFO] Install dependencies"
python3 -m pip install -r requirements.txt ruff >/tmp/day14_pip.log 2>&1 || (cat /tmp/day14_pip.log && exit 1)

echo "[INFO] Prepare test database schema"
python3 - <<'PY'
import os
import time
from pathlib import Path

import psycopg

db_url = os.environ["DATABASE_URL"]
conn_url = db_url.replace("postgresql+psycopg://", "postgresql://", 1)
sql = (Path("db/migrations/0001_init.sql")).read_text(encoding="utf-8")

for _ in range(40):
    try:
        with psycopg.connect(conn_url, autocommit=True) as conn:
            with conn.cursor() as cur:
                cur.execute("DROP SCHEMA IF EXISTS public CASCADE;")
                cur.execute("CREATE SCHEMA public;")
                cur.execute(sql)
        break
    except Exception:
        time.sleep(1)
else:
    raise SystemExit("database is not reachable")
PY

echo "[INFO] Lint (ruff critical rules)"
python3 -m ruff check --select E9,F63,F7,F82 .

echo "[INFO] Run tests"
export TEST_DB_RESET_MODE=skip
PYTHONPATH=. python3 -m pytest -q tests

echo "[INFO] Compile checks"
python3 -m compileall -q backend tests monitoring blogsnap app.py main.py

echo "[INFO] Env checks"
./scripts/day12_env_check.sh .env.example

echo "[OK] Day14 CI suite passed"
