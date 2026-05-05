#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RETENTION_HOURS="${1:-24}"
export RETENTION_HOURS

echo "[INFO] running asset cleanup for all projects (retention_hours=${RETENTION_HOURS})"

PYTHONPATH=. python3 - <<'PY'
import json
import os

from backend.app.db.session import SessionLocal
from backend.app.services.asset_cleanup import purge_deleted_assets_all_projects

retention_hours = int(os.environ.get("RETENTION_HOURS", "24"))

with SessionLocal() as db:
    result = purge_deleted_assets_all_projects(db, retention_hours=retention_hours)

print(json.dumps({"status": "ok", **result}, ensure_ascii=False))
PY

echo "[OK] day30 asset cleanup run completed"
