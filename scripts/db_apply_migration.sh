#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATION_FILE="${1:-$ROOT_DIR/db/migrations/0001_init.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "[ERROR] Migration file not found: $MIGRATION_FILE"
  exit 1
fi

echo "[INFO] Starting postgres container..."
docker compose -f "$ROOT_DIR/docker-compose.dev.yml" up -d postgres

echo "[INFO] Waiting for postgres to be healthy..."
ATTEMPTS=0
until docker exec blogsnap-postgres pg_isready -U blogsnap -d blogsnap >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [[ $ATTEMPTS -gt 30 ]]; then
    echo "[ERROR] Postgres health check timed out."
    exit 1
  fi
  sleep 1
done

echo "[INFO] Applying migration: $MIGRATION_FILE"
docker exec -i blogsnap-postgres psql -v ON_ERROR_STOP=1 -U blogsnap -d blogsnap < "$MIGRATION_FILE"

echo "[OK] Migration applied successfully."
