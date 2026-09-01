#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap}"
export DATABASE_URL

PYTHON_BIN="python3"
if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="python3.11"
fi

echo "[INFO] Install dependencies"
"$PYTHON_BIN" -m pip install -r requirements.txt ruff >/tmp/day14_pip.log 2>&1 || (cat /tmp/day14_pip.log && exit 1)

echo "[INFO] Prepare test database schema"
"$PYTHON_BIN" - <<'PY'
import os
import re
import time
from pathlib import Path

import psycopg

# tests/conftest.py forces the suite onto a distinct "<name>_test" database
# (so a full DROP SCHEMA reset never touches the primary dev DB). The CI run
# uses TEST_DB_RESET_MODE=skip, so nothing else creates that DB — do it here,
# deriving the name the exact same way conftest does.
base_url = os.environ["DATABASE_URL"]
test_url = re.sub(r"/([^/]+)$", lambda m: f"/{m.group(1)}_test", base_url)
conn_url = test_url.replace("postgresql+psycopg://", "postgresql://", 1)
admin_url = re.sub(r"/([^/]+)$", "/postgres", conn_url)
test_db_name = conn_url.rsplit("/", 1)[-1]
sql = (Path("db/migrations/0001_init.sql")).read_text(encoding="utf-8")

for _ in range(40):
    try:
        with psycopg.connect(admin_url, autocommit=True) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT 1 FROM pg_database WHERE datname = %s", (test_db_name,)
                )
                if cur.fetchone() is None:
                    cur.execute(f'CREATE DATABASE "{test_db_name}"')
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
"$PYTHON_BIN" -m ruff check --select E9,F63,F7,F82 .

echo "[INFO] Run tests"
export TEST_DB_RESET_MODE=skip
PYTHONPATH=. "$PYTHON_BIN" -m pytest -q tests

echo "[INFO] Compile checks"
"$PYTHON_BIN" -m compileall -q backend tests monitoring blogsnap app.py main.py

echo "[INFO] Env checks"
./scripts/day12_env_check.sh .env.example

echo "[OK] Day14 CI suite passed"
