#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[INFO] Ensure dependencies"
python3 -m pip install -r requirements.txt >/tmp/day13_pip.log 2>&1 || (cat /tmp/day13_pip.log && exit 1)

echo "[INFO] Reset DB"
./scripts/db_reset.sh >/tmp/day13_db_reset.log 2>&1 || (cat /tmp/day13_db_reset.log && exit 1)

echo "[INFO] Run pytest suite"
PYTHONPATH=. python3 -m pytest -q tests

echo "[OK] Day13 test suite passed"
