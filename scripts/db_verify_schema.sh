#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-blogsnap}"

echo "[INFO] Verifying tables in $DB_NAME..."
docker exec -i blogsnap-postgres psql -U blogsnap -d "$DB_NAME" -c "\dt"

echo "[INFO] Verifying enum types..."
docker exec -i blogsnap-postgres psql -U blogsnap -d "$DB_NAME" -c "SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname;"

echo "[OK] Schema verification query completed."
