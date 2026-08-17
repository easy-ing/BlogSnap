#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_NAME="${DB_NAME:-blogsnap}"

docker compose -f "$ROOT_DIR/docker-compose.dev.yml" up -d postgres

if [[ "$DB_NAME" == "blogsnap" ]]; then
  echo "[WARN] DB_NAME=blogsnap — this resets the PRIMARY dev/demo database (real connected keys, projects, drafts will be wiped)."
  echo "[WARN] Tests should instead set DB_NAME=blogsnap_test (tests/conftest.py already does this automatically)."
fi

echo "[INFO] Ensuring database exists: $DB_NAME"
docker exec -i blogsnap-postgres psql -v ON_ERROR_STOP=1 -U blogsnap -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
  docker exec -i blogsnap-postgres psql -v ON_ERROR_STOP=1 -U blogsnap -d postgres -c "CREATE DATABASE \"$DB_NAME\";"

echo "[INFO] Resetting public schema in $DB_NAME..."
docker exec -i blogsnap-postgres psql -v ON_ERROR_STOP=1 -U blogsnap -d "$DB_NAME" -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;"

DB_NAME="$DB_NAME" "$ROOT_DIR/scripts/db_apply_migration.sh"
DB_NAME="$DB_NAME" "$ROOT_DIR/scripts/db_verify_schema.sh"

echo "[OK] Database reset + migration + verification completed for $DB_NAME."
