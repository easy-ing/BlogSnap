#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Verifying tables..."
docker exec -i blogsnap-postgres psql -U blogsnap -d blogsnap -c "\dt"

echo "[INFO] Verifying enum types..."
docker exec -i blogsnap-postgres psql -U blogsnap -d blogsnap -c "SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname;"

echo "[OK] Schema verification query completed."
