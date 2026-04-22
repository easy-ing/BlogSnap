#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://blogsnap:blogsnap@127.0.0.1:55432/blogsnap}"
export WORKER_PUBLISH_MODE="mock"

./scripts/db_reset.sh >/tmp/day19_db_reset.log 2>&1 || (cat /tmp/day19_db_reset.log && exit 1)

python3 -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 >/tmp/day19_api.log 2>&1 &
API_PID=$!
trap 'kill $API_PID >/dev/null 2>&1 || true' EXIT

for _ in {1..60}; do
  if curl -fsS http://127.0.0.1:8000/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

LOGIN_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"day19-demo@blogsnap.local","display_name":"Day19 Demo"}')
TOKEN=$(echo "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')
AUTH_HEADER="Authorization: Bearer $TOKEN"

PROJECT_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/projects \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d '{"name":"Day19 Multi Provider Project"}')
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')

GEN_JSON=$(curl -sS -X POST http://127.0.0.1:8000/v1/drafts/generate \
  -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
  -d "{\"project_id\":\"$PROJECT_ID\",\"post_type\":\"explanation\",\"keyword\":\"Day19 멀티 프로바이더\",\"sentiment\":1,\"draft_count\":2}")
GEN_JOB_ID=$(echo "$GEN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')
curl -sS -X POST "http://127.0.0.1:8000/v1/jobs/$GEN_JOB_ID/run" -H "$AUTH_HEADER" >/tmp/day19_gen_run.json

DRAFT_ID=$(curl -sS "http://127.0.0.1:8000/v1/drafts?project_id=$PROJECT_ID" -H "$AUTH_HEADER" | python3 -c 'import sys,json; print(json.load(sys.stdin)[0]["id"])')
curl -sS -X POST "http://127.0.0.1:8000/v1/drafts/$DRAFT_ID/select" -H "$AUTH_HEADER" >/tmp/day19_select.json

publish_and_assert() {
  local provider="$1"
  local key="$2"
  local publish_json job_id run_json run_status publish_id publish_status publish_url

  publish_json="$(curl -sS -X POST http://127.0.0.1:8000/v1/publish \
    -H "$AUTH_HEADER" -H 'Content-Type: application/json' \
    -d "{\"project_id\":\"$PROJECT_ID\",\"draft_id\":\"$DRAFT_ID\",\"provider\":\"$provider\",\"idempotency_key\":\"$key\"}")"
  job_id="$(echo "$publish_json" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')"

  run_json="$(curl -sS -X POST "http://127.0.0.1:8000/v1/jobs/$job_id/run" -H "$AUTH_HEADER")"
  run_status="$(echo "$run_json" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')"
  if [[ "$run_status" != "SUCCEEDED" ]]; then
    echo "[ERROR] provider=$provider run status expected SUCCEEDED, got: $run_status"
    echo "$run_json"
    exit 1
  fi

  publish_id="$(echo "$run_json" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("result_payload",{}).get("publish_job_id",""))')"
  publish_job_json="$(curl -sS "http://127.0.0.1:8000/v1/publish/$publish_id" -H "$AUTH_HEADER")"
  publish_status="$(echo "$publish_job_json" | python3 -c 'import sys,json; print(json.load(sys.stdin)["status"])')"
  publish_url="$(echo "$publish_job_json" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("post_url",""))')"

  if [[ "$publish_status" != "PUBLISHED" ]]; then
    echo "[ERROR] provider=$provider publish status expected PUBLISHED, got: $publish_status"
    echo "$publish_job_json"
    exit 1
  fi

  if [[ "$publish_url" != *"/$provider/"* ]]; then
    echo "[ERROR] provider=$provider mock url path mismatch: $publish_url"
    exit 1
  fi

  echo "[INFO] provider=$provider published url=$publish_url"
}

publish_and_assert "wordpress" "day19-wp-$(date +%s)"
publish_and_assert "tistory" "day19-ti-$(date +%s)"

echo "[OK] Day19 multi-provider demo passed"
