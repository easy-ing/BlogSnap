#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker compose -f "$ROOT_DIR/docker-compose.dev.yml" up -d postgres

echo "[INFO] Resetting public schema..."
docker exec -i blogsnap-postgres psql -v ON_ERROR_STOP=1 -U blogsnap -d blogsnap -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;"

"$ROOT_DIR/scripts/db_apply_migration.sh"
"$ROOT_DIR/scripts/db_verify_schema.sh"

echo "[OK] Database reset + migration + verification completed."
