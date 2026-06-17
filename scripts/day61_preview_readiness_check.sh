#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

API_URL="${API_URL:-http://127.0.0.1:8000}"
FRONTEND_URL="${FRONTEND_URL:-http://127.0.0.1:5173}"
PREVIEW_TIMEOUT_SECONDS="${PREVIEW_TIMEOUT_SECONDS:-5}"
PREVIEW_STRICT="${PREVIEW_STRICT:-no}"
RUN_FRONTEND_BUILD="${RUN_FRONTEND_BUILD:-yes}"
REFRESH_DAY60="${REFRESH_DAY60:-yes}"
EXPECT_API_ROOT_404="${EXPECT_API_ROOT_404:-yes}"
DEPLOY_TARGET="${DEPLOY_TARGET:-staging}"
DEPLOY_ACTION="${DEPLOY_ACTION:-dry-run}"
CONFIRM_DEPLOY="${CONFIRM_DEPLOY:-no}"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day61-preview-readiness-$TS.md"
OUT_JSON="$OUT_DIR/day61-preview-readiness-$TS.json"
LATEST_MD="$OUT_DIR/day61-preview-readiness-latest.md"
LATEST_JSON="$OUT_DIR/day61-preview-readiness-latest.json"

DAY60_JSON="$OUT_DIR/day60-post-deploy-smoke-latest.json"

echo "# Day61 Preview Readiness Check" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- api_url: $API_URL" >> "$OUT_MD"
echo "- frontend_url: $FRONTEND_URL" >> "$OUT_MD"
echo "- preview_strict: $PREVIEW_STRICT" >> "$OUT_MD"
echo "- run_frontend_build: $RUN_FRONTEND_BUILD" >> "$OUT_MD"
echo "" >> "$OUT_MD"

if [[ "$REFRESH_DAY60" == "yes" ]]; then
  echo "[STEP] Refresh Day60 post-deploy smoke check"
  API_URL="$API_URL" \
    DEPLOY_TARGET="$DEPLOY_TARGET" \
    DEPLOY_ACTION="$DEPLOY_ACTION" \
    CONFIRM_DEPLOY="$CONFIRM_DEPLOY" \
    SMOKE_STRICT=no \
    ./scripts/day60_post_deploy_smoke_check.sh "$REPORT_DIR" "$OUT_DIR" >> "$OUT_MD"
else
  echo "[INFO] REFRESH_DAY60=no; using existing Day60 latest if present" >> "$OUT_MD"
fi

python3 - <<'PY' "$DAY60_JSON" "$OUT_JSON" "$OUT_MD" "$TS"
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

day60_path = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
ts = sys.argv[4]

api_url = os.environ.get("API_URL", "http://127.0.0.1:8000").rstrip("/")
frontend_url = os.environ.get("FRONTEND_URL", "http://127.0.0.1:5173").rstrip("/")
timeout = float(os.environ.get("PREVIEW_TIMEOUT_SECONDS", "5"))
strict = os.environ.get("PREVIEW_STRICT", "no").lower() == "yes"
run_build = os.environ.get("RUN_FRONTEND_BUILD", "yes").lower() == "yes"
expect_api_root_404 = os.environ.get("EXPECT_API_ROOT_404", "yes").lower() == "yes"

current_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
current_branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()

checks = []
artifacts = {}


def add_check(name, required, passed, detail, category="preview"):
    checks.append(
        {
            "name": name,
            "category": category,
            "required": required,
            "status": "pass" if passed else "fail",
            "detail": detail,
        }
    )


def request(path):
    started = time.perf_counter()
    try:
        with urllib.request.urlopen(path, timeout=timeout) as response:
            body = response.read().decode("utf-8", errors="replace")
            return {
                "ok": 200 <= response.status < 300,
                "status_code": response.status,
                "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
                "body": body[:12000],
                "error": "",
                "url": path,
            }
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        return {
            "ok": False,
            "status_code": exc.code,
            "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
            "body": body[:12000],
            "error": str(exc),
            "url": path,
        }
    except Exception as exc:
        return {
            "ok": False,
            "status_code": None,
            "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
            "body": "",
            "error": f"{type(exc).__name__}: {exc}",
            "url": path,
        }


def json_status(response):
    try:
        payload = json.loads(response.get("body", ""))
    except json.JSONDecodeError:
        return ""
    if isinstance(payload, dict):
        return str(payload.get("status", ""))
    return ""


vite_config = Path("frontend/vite.config.ts")
env_example = Path("frontend/.env.example")
frontend_readme = Path("frontend/README.md")
root_readme = Path("README.md")

vite_text = vite_config.read_text(encoding="utf-8") if vite_config.exists() else ""
env_text = env_example.read_text(encoding="utf-8") if env_example.exists() else ""
frontend_readme_text = frontend_readme.read_text(encoding="utf-8") if frontend_readme.exists() else ""
root_readme_text = root_readme.read_text(encoding="utf-8") if root_readme.exists() else ""

add_check(
    "vite_proxy_configured",
    True,
    "VITE_API_PROXY_TARGET" in vite_text and "http://localhost:8000" in vite_text and '"/api"' in vite_text,
    "vite proxy should default /api to http://localhost:8000 and allow VITE_API_PROXY_TARGET override",
    category="config",
)
add_check(
    "frontend_env_documents_proxy",
    True,
    "VITE_API_BASE=/api" in env_text and "VITE_API_PROXY_TARGET=http://localhost:8000" in env_text,
    "frontend .env.example should document VITE_API_BASE and VITE_API_PROXY_TARGET",
    category="config",
)
add_check(
    "preview_docs_include_correct_urls",
    True,
    "http://localhost:5173" in frontend_readme_text
    and "http://localhost:8000" in frontend_readme_text
    and "http://localhost:5173" in root_readme_text,
    "README docs should identify frontend preview URL and backend API URL",
    category="docs",
)

day60 = {}
if day60_path.exists():
    day60 = json.loads(day60_path.read_text(encoding="utf-8"))
day60_status = day60.get("smoke_status", "missing")
day60_commit = day60.get("git", {}).get("commit", "")
day60_branch = day60.get("git", {}).get("branch", "")
add_check(
    "day60_smoke_ready",
    True,
    day60_status == "ready",
    f"smoke_status={day60_status}",
    category="evidence",
)
add_check(
    "day60_commit_matches_head",
    True,
    day60_commit == current_commit,
    f"day60_commit={day60_commit or 'missing'}, head={current_commit}",
    category="evidence",
)
add_check(
    "day60_branch_matches_current",
    True,
    day60_branch == current_branch,
    f"day60_branch={day60_branch or 'missing'}, branch={current_branch}",
    category="evidence",
)

api_root = request(f"{api_url}/")
artifacts["api_root"] = {k: v for k, v in api_root.items() if k != "body"}
api_root_passed = api_root["status_code"] == 404 if expect_api_root_404 else api_root["status_code"] is not None
add_check(
    "api_root_expected",
    True,
    api_root_passed,
    f"status_code={api_root['status_code']}, expected_404={expect_api_root_404}, error={api_root['error'] or 'none'}",
    category="runtime",
)

api_health = request(f"{api_url}/health")
artifacts["api_health"] = {k: v for k, v in api_health.items() if k != "body"}
add_check(
    "api_health_ready",
    True,
    api_health["ok"] and json_status(api_health) == "ok",
    f"status_code={api_health['status_code']}, status={json_status(api_health) or 'missing'}, error={api_health['error'] or 'none'}",
    category="runtime",
)

frontend_root = request(f"{frontend_url}/")
artifacts["frontend_root"] = {k: v for k, v in frontend_root.items() if k != "body"}
frontend_body = frontend_root.get("body", "")
frontend_root_ok = frontend_root["ok"] and '<div id="root"></div>' in frontend_body and (
    "/src/main.tsx" in frontend_body or "/assets/" in frontend_body
)
add_check(
    "frontend_preview_root",
    True,
    frontend_root_ok,
    f"status_code={frontend_root['status_code']}, has_root={'<div id=\"root\"></div>' in frontend_body}, error={frontend_root['error'] or 'none'}",
    category="runtime",
)

proxy_health = request(f"{frontend_url}/api/health")
artifacts["frontend_proxy_health"] = {k: v for k, v in proxy_health.items() if k != "body"}
add_check(
    "frontend_api_proxy_health",
    True,
    proxy_health["ok"] and json_status(proxy_health) == "ok",
    f"status_code={proxy_health['status_code']}, status={json_status(proxy_health) or 'missing'}, error={proxy_health['error'] or 'none'}",
    category="runtime",
)

build_result = {
    "checked": run_build,
    "return_code": None,
    "elapsed_ms": 0,
    "tail": "",
}
if run_build:
    started = time.perf_counter()
    proc = subprocess.run(
        ["npm", "run", "build"],
        cwd="frontend",
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=max(timeout, 5) * 12,
        check=False,
    )
    build_result = {
        "checked": True,
        "return_code": proc.returncode,
        "elapsed_ms": round((time.perf_counter() - started) * 1000, 2),
        "tail": "\n".join(proc.stdout.splitlines()[-12:]),
    }
    add_check(
        "frontend_build",
        True,
        proc.returncode == 0,
        f"return_code={proc.returncode}",
        category="build",
    )
else:
    add_check(
        "frontend_build",
        False,
        True,
        "skipped because RUN_FRONTEND_BUILD=no",
        category="build",
    )
artifacts["frontend_build"] = build_result

required_failed = [check for check in checks if check["required"] and check["status"] != "pass"]
optional_failed = [check for check in checks if not check["required"] and check["status"] != "pass"]

if required_failed:
    preview_status = "failed"
elif optional_failed:
    preview_status = "needs_attention"
else:
    preview_status = "ready"

next_actions = []
if required_failed:
    next_actions.append("Fix failed preview readiness checks before asking users to test the web preview.")
    if any(check["name"] == "frontend_preview_root" for check in required_failed):
        next_actions.append("Start the frontend with: cd frontend && npm run dev -- --host 0.0.0.0")
    if any(check["name"] == "frontend_api_proxy_health" for check in required_failed):
        next_actions.append("Confirm VITE_API_PROXY_TARGET points to the running backend API.")
    if any(check["name"] == "api_health_ready" for check in required_failed):
        next_actions.append("Start the backend stack with: docker compose -f docker-compose.dev.yml up -d postgres api worker")
else:
    next_actions.append("Open the web preview at the frontend URL, not the backend API root.")
    next_actions.append("Use the backend URL for /health and /docs checks only.")

payload = {
    "status": "ok",
    "preview_status": preview_status,
    "generated_at_utc": ts,
    "frontend_url": frontend_url,
    "api_url": api_url,
    "strict": strict,
    "git": {
        "branch": current_branch,
        "commit": current_commit,
    },
    "day60": {
        "path": str(day60_path),
        "smoke_status": day60_status,
        "branch": day60_branch,
        "commit": day60_commit,
    },
    "checks": checks,
    "required_failed": required_failed,
    "optional_failed": optional_failed,
    "artifacts": artifacts,
    "operator_urls": {
        "open_preview": f"{frontend_url}/",
        "api_health": f"{api_url}/health",
        "api_docs": f"{api_url}/docs",
        "api_root_note": "The backend API root may return 404. Use /health or /docs for API checks.",
    },
    "next_actions": next_actions,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "",
    "## Preview Status",
    f"- preview_status: {preview_status}",
    f"- frontend_url: {frontend_url}/",
    f"- api_url: {api_url}",
    f"- git_branch: {current_branch}",
    f"- git_commit: {current_commit}",
    f"- day60_smoke_status: {day60_status}",
    "",
    "## Operator URLs",
    f"- web_preview: {frontend_url}/",
    f"- api_health: {api_url}/health",
    f"- api_docs: {api_url}/docs",
    "- api_root_note: Backend API root can return 404; this is not the web preview.",
    "",
    "## Checks",
]
for check in checks:
    marker = "PASS" if check["status"] == "pass" else "FAIL"
    required_label = "required" if check["required"] else "optional"
    lines.append(f"- {marker}: {check['name']} ({required_label}) - {check['detail']}")

lines.append("")
lines.append("## Runtime Artifacts")
for name, artifact in artifacts.items():
    if name == "frontend_build":
        lines.append(
            f"- {name}: checked={artifact.get('checked')} return_code={artifact.get('return_code')} elapsed_ms={artifact.get('elapsed_ms')}"
        )
    else:
        lines.append(
            f"- {name}: status_code={artifact.get('status_code')} elapsed_ms={artifact.get('elapsed_ms')} url={artifact.get('url')}"
        )

lines.append("")
lines.append("## Next Actions")
for action in next_actions:
    lines.append(f"- {action}")

lines.extend(
    [
        "",
        "## Operator Notes",
        "- Open the frontend URL for the product UI.",
        "- Open the backend URL only for API health and OpenAPI docs.",
        "- Use PREVIEW_STRICT=yes to return a non-zero exit code when preview_status is not ready.",
        "",
        "[OK] Day61 preview readiness report generated",
    ]
)

with out_md.open("a", encoding="utf-8") as f:
    f.write("\n".join(lines))
    f.write("\n")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day61 preview readiness report generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"

PREVIEW_STATUS="$(python3 - <<'PY' "$OUT_JSON"
import json
import sys
from pathlib import Path

print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("preview_status", "unknown"))
PY
)"

if [[ "$PREVIEW_STRICT" == "yes" && "$PREVIEW_STATUS" != "ready" ]]; then
  echo "[ERROR] Day61 preview_status=$PREVIEW_STATUS"
  exit 2
fi
