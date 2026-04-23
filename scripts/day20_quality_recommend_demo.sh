#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap}"
API_PORT="${API_PORT:-8010}"
BASE_URL="http://127.0.0.1:${API_PORT}"

./scripts/db_reset.sh >/tmp/day20_db_reset.log 2>&1 || (cat /tmp/day20_db_reset.log && exit 1)

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port "$API_PORT" >/tmp/day20_api.log 2>&1 &
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
  -d '{"email":"day20-demo@blogsnap.local","display_name":"Day20 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"

PROJECT_JSON=$(curl -sS -X POST "${BASE_URL}/v1/projects" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d '{"name":"Day20 Recommendation Project"}')
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

GEN_JSON=$(curl -sS -X POST "${BASE_URL}/v1/drafts/generate" \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"post_type\":\"review\",\"keyword\":\"Day20 추천\",\"sentiment\":1,\"draft_count\":3}")
GEN_JOB_ID=$(echo "$GEN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
curl -sS -X POST "${BASE_URL}/v1/jobs/$GEN_JOB_ID/run" -H "$AUTH_HEADER" >/tmp/day20_gen_run.json

RECOMMEND_JSON=$(curl -sS "${BASE_URL}/v1/drafts/recommend?project_id=$PROJECT_ID" -H "$AUTH_HEADER")

python3 -c '
import json
import sys

payload = json.load(sys.stdin)
candidates = payload.get("candidates", [])
if not payload.get("recommended_draft_id") or len(candidates) < 2:
    raise SystemExit("[ERROR] invalid recommendation payload")
print("[INFO] recommended_draft_id=", payload["recommended_draft_id"])
print("[INFO] recommended_title=", payload["recommended_title"])
print("[INFO] top_score=", candidates[0]["quality_score"])
' <<<"$RECOMMEND_JSON"

echo "[OK] Day20 quality recommendation demo passed"
