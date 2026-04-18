#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker compose -f docker-compose.dev.yml up -d --build postgres api worker >/tmp/day17_stack.log 2>&1 || (cat /tmp/day17_stack.log && exit 1)
./scripts/db_reset.sh >/tmp/day17_db.log 2>&1 || (cat /tmp/day17_db.log && exit 1)
docker compose -f docker-compose.dev.yml up -d --build api worker >/tmp/day17_api.log 2>&1 || (cat /tmp/day17_api.log && exit 1)

for _ in {1..90}; do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

login() {
  local email="$1"
  curl -fsS -X POST http://127.0.0.1:8000/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"display_name\":\"${email%%@*}\"}"
}

TOKEN_A="$(login day17-user-a@blogsnap.local | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')"
TOKEN_B="$(login day17-user-b@blogsnap.local | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')"
HDR_A="Authorization: Bearer ${TOKEN_A}"
HDR_B="Authorization: Bearer ${TOKEN_B}"

PROJECT_ID="$(curl -fsS -X POST http://127.0.0.1:8000/v1/projects -H "$HDR_A" -H 'Content-Type: application/json' -d '{"name":"Day17 RBAC Project"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')"

JOB_ID="$(curl -fsS -X POST http://127.0.0.1:8000/v1/drafts/generate -H "$HDR_A" -H 'Content-Type: application/json' -d "{\"project_id\":\"${PROJECT_ID}\",\"post_type\":\"explanation\",\"keyword\":\"Day17 인증\",\"sentiment\":1,\"draft_count\":2}" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')"
curl -fsS -X POST "http://127.0.0.1:8000/v1/jobs/${JOB_ID}/run" -H "$HDR_A" >/tmp/day17_run.json

echo "[INFO] owner access check"
curl -fsS "http://127.0.0.1:8000/v1/drafts?project_id=${PROJECT_ID}" -H "$HDR_A" >/tmp/day17_owner.json
OWNER_COUNT="$(python3 - << 'PY'
import json
with open("/tmp/day17_owner.json", "r", encoding="utf-8") as fh:
    print(len(json.load(fh)))
PY
)"
echo "owner_drafts_count=${OWNER_COUNT}"

echo "[INFO] cross-user denied check"
HTTP_CODE="$(curl -sS -o /tmp/day17_denied.json -w '%{http_code}' "http://127.0.0.1:8000/v1/drafts?project_id=${PROJECT_ID}" -H "$HDR_B")"
if [[ "$HTTP_CODE" != "403" ]]; then
  echo "[ERROR] expected 403 for cross-user access, got: $HTTP_CODE"
  cat /tmp/day17_denied.json
  exit 1
fi

echo "[OK] Day17 auth/rbac demo passed"
