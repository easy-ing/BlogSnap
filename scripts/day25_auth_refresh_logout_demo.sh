#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap}"
API_PORT="${API_PORT:-8025}"
BASE_URL="http://127.0.0.1:${API_PORT}"

./scripts/db_reset.sh >/tmp/day25_db_reset.log 2>&1 || (cat /tmp/day25_db_reset.log && exit 1)

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port "$API_PORT" >/tmp/day25_api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID >/dev/null 2>&1 || true' EXIT

for _ in {1..60}; do
  if curl -fsS "${BASE_URL}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

LOGIN_JSON=$(curl -sS -X POST "${BASE_URL}/v1/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"day25-demo@blogsnap.local","display_name":"Day25 Demo"}')
ACCESS_TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
REFRESH_TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["refresh_token"])')

ME_JSON=$(curl -sS "${BASE_URL}/v1/auth/me" -H "Authorization: Bearer $ACCESS_TOKEN")
ME_EMAIL=$(echo "$ME_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["email"])')
if [[ "$ME_EMAIL" != "day25-demo@blogsnap.local" ]]; then
  echo "[ERROR] /me validation failed"
  echo "$ME_JSON"
  exit 1
fi

REFRESH_JSON=$(curl -sS -X POST "${BASE_URL}/v1/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refresh_token\":\"$REFRESH_TOKEN\"}")
NEW_REFRESH_TOKEN=$(echo "$REFRESH_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["refresh_token"])')
if [[ "$NEW_REFRESH_TOKEN" == "$REFRESH_TOKEN" ]]; then
  echo "[ERROR] refresh token should be rotated"
  echo "$REFRESH_JSON"
  exit 1
fi

curl -sS -X POST "${BASE_URL}/v1/auth/logout" \
  -H 'Content-Type: application/json' \
  -d "{\"refresh_token\":\"$NEW_REFRESH_TOKEN\"}" >/tmp/day25_logout.json

REFRESH_AFTER_LOGOUT_CODE=$(curl -sS -o /tmp/day25_refresh_after_logout.json -w '%{http_code}' -X POST "${BASE_URL}/v1/auth/refresh" \
  -H 'Content-Type: application/json' \
  -d "{\"refresh_token\":\"$NEW_REFRESH_TOKEN\"}")
if [[ "$REFRESH_AFTER_LOGOUT_CODE" != "401" ]]; then
  echo "[ERROR] refresh after logout should be 401, got: $REFRESH_AFTER_LOGOUT_CODE"
  cat /tmp/day25_refresh_after_logout.json
  exit 1
fi

echo "[OK] Day25 auth refresh/logout demo passed"
