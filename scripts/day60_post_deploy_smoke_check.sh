#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

DEPLOY_TARGET="${DEPLOY_TARGET:-staging}"
DEPLOY_ACTION="${DEPLOY_ACTION:-dry-run}"
CONFIRM_DEPLOY="${CONFIRM_DEPLOY:-no}"
API_URL="${API_URL:-http://127.0.0.1:8000}"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-5}"
SMOKE_STRICT="${SMOKE_STRICT:-no}"
METRICS_REQUIRED="${METRICS_REQUIRED:-yes}"
WORKER_CHECK_REQUIRED="${WORKER_CHECK_REQUIRED:-no}"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day60-post-deploy-smoke-$TS.md"
OUT_JSON="$OUT_DIR/day60-post-deploy-smoke-$TS.json"
LATEST_MD="$OUT_DIR/day60-post-deploy-smoke-latest.md"
LATEST_JSON="$OUT_DIR/day60-post-deploy-smoke-latest.json"

DAY59_JSON="$OUT_DIR/day59-post-deploy-verification-latest.json"

echo "# Day60 Post-Deploy Smoke Check" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- deploy_target: $DEPLOY_TARGET" >> "$OUT_MD"
echo "- deploy_action: $DEPLOY_ACTION" >> "$OUT_MD"
echo "- api_url: $API_URL" >> "$OUT_MD"
echo "- smoke_strict: $SMOKE_STRICT" >> "$OUT_MD"
echo "" >> "$OUT_MD"

echo "[STEP] Refresh Day59 post-deploy verification"
DEPLOY_TARGET="$DEPLOY_TARGET" \
  DEPLOY_ACTION="$DEPLOY_ACTION" \
  CONFIRM_DEPLOY="$CONFIRM_DEPLOY" \
  ./scripts/day59_post_deploy_verification.sh "$REPORT_DIR" "$OUT_DIR" >> "$OUT_MD"

if [[ ! -f "$DAY59_JSON" ]]; then
  echo "[ERROR] missing Day59 verification json: $DAY59_JSON"
  exit 1
fi

python3 - <<'PY' "$DAY59_JSON" "$OUT_JSON" "$OUT_MD" "$TS"
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

day59_path = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
ts = sys.argv[4]

api_url = os.environ.get("API_URL", "http://127.0.0.1:8000").rstrip("/")
timeout = float(os.environ.get("SMOKE_TIMEOUT_SECONDS", "5"))
strict = os.environ.get("SMOKE_STRICT", "no").lower() == "yes"
metrics_required = os.environ.get("METRICS_REQUIRED", "yes").lower() == "yes"
worker_check_required = os.environ.get("WORKER_CHECK_REQUIRED", "no").lower() == "yes"

current_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
current_branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()
day59 = json.loads(day59_path.read_text(encoding="utf-8"))

checks = []
artifacts = {}


def add_check(name, required, passed, detail, category="runtime", severity=None):
    if severity is None:
        severity = "required" if required else "optional"
    checks.append(
        {
            "name": name,
            "category": category,
            "required": required,
            "status": "pass" if passed else "fail",
            "severity": severity,
            "detail": detail,
        }
    )


def request(method, path, body=None, headers=None):
    url = path if path.startswith("http") else f"{api_url}{path}"
    headers = headers or {}
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers = {"Content-Type": "application/json", **headers}

    started = time.perf_counter()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            raw = response.read()
            elapsed_ms = round((time.perf_counter() - started) * 1000, 2)
            text = raw.decode("utf-8", errors="replace")
            parsed = None
            try:
                parsed = json.loads(text)
            except json.JSONDecodeError:
                parsed = None
            return {
                "ok": 200 <= response.status < 300,
                "status_code": response.status,
                "elapsed_ms": elapsed_ms,
                "body": text[:12000],
                "json": parsed,
                "error": "",
                "url": url,
            }
    except urllib.error.HTTPError as exc:
        elapsed_ms = round((time.perf_counter() - started) * 1000, 2)
        raw = exc.read()
        text = raw.decode("utf-8", errors="replace")
        return {
            "ok": False,
            "status_code": exc.code,
            "elapsed_ms": elapsed_ms,
            "body": text[:12000],
            "json": None,
            "error": str(exc),
            "url": url,
        }
    except Exception as exc:
        elapsed_ms = round((time.perf_counter() - started) * 1000, 2)
        return {
            "ok": False,
            "status_code": None,
            "elapsed_ms": elapsed_ms,
            "body": "",
            "json": None,
            "error": f"{type(exc).__name__}: {exc}",
            "url": url,
        }


def status_value(response):
    payload = response.get("json")
    if isinstance(payload, dict):
        return str(payload.get("status", ""))
    return ""


day59_ready = day59.get("verification_status") == "ready"
add_check(
    "day59_verification_ready",
    True,
    day59_ready,
    f"verification_status={day59.get('verification_status', 'missing')}",
    category="evidence",
)

day59_commit = day59.get("git", {}).get("commit", "")
day59_branch = day59.get("git", {}).get("branch", "")
add_check(
    "day59_commit_matches_head",
    True,
    day59_commit == current_commit,
    f"day59_commit={day59_commit}, head={current_commit}",
    category="evidence",
)
add_check(
    "day59_branch_matches_current",
    True,
    day59_branch == current_branch,
    f"day59_branch={day59_branch}, branch={current_branch}",
    category="evidence",
)

health = request("GET", "/health")
artifacts["health"] = {k: v for k, v in health.items() if k != "body"}
add_check(
    "api_health",
    True,
    health["ok"] and status_value(health) == "ok",
    f"status_code={health['status_code']}, status={status_value(health) or 'missing'}, error={health['error'] or 'none'}",
)

ready = request("GET", "/health/ready")
artifacts["readiness"] = {k: v for k, v in ready.items() if k != "body"}
add_check(
    "api_readiness",
    True,
    ready["ok"] and status_value(ready) == "ready",
    f"status_code={ready['status_code']}, status={status_value(ready) or 'missing'}, error={ready['error'] or 'none'}",
)

email = f"day60-smoke-{ts.lower()}@blogsnap.local"
login = request(
    "POST",
    "/v1/auth/login",
    {
        "email": email,
        "display_name": "Day60 Smoke",
    },
)
artifacts["login"] = {k: v for k, v in login.items() if k != "body"}
token = ""
if isinstance(login.get("json"), dict):
    token = str(login["json"].get("access_token", ""))
add_check(
    "auth_login",
    True,
    login["ok"] and bool(token),
    f"status_code={login['status_code']}, token_present={bool(token)}, error={login['error'] or 'none'}",
)

project_id = ""
project = {
    "ok": False,
    "status_code": None,
    "elapsed_ms": 0,
    "json": None,
    "error": "auth token missing",
    "url": f"{api_url}/v1/projects",
}
if token:
    project = request(
        "POST",
        "/v1/projects",
        {"name": f"Day60 Smoke {ts}"},
        {"Authorization": f"Bearer {token}"},
    )
    if isinstance(project.get("json"), dict):
        project_id = str(project["json"].get("id", ""))
artifacts["project"] = {k: v for k, v in project.items() if k != "body"}
add_check(
    "project_create",
    True,
    project["ok"] and bool(project_id),
    f"status_code={project['status_code']}, project_id_present={bool(project_id)}, error={project['error'] or 'none'}",
)

queue = {
    "ok": False,
    "status_code": None,
    "elapsed_ms": 0,
    "json": None,
    "error": "project id or auth token missing",
    "url": f"{api_url}/v1/jobs/queue-summary",
}
if token and project_id:
    queue = request(
        "GET",
        f"/v1/jobs/queue-summary?project_id={project_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
artifacts["queue_summary"] = {k: v for k, v in queue.items() if k != "body"}
queue_payload = queue.get("json") if isinstance(queue.get("json"), dict) else {}
queue_keys = {"pending", "retrying", "running", "failed", "succeeded"}
add_check(
    "queue_summary",
    True,
    queue["ok"] and queue_keys.issubset(set(queue_payload.keys())),
    f"status_code={queue['status_code']}, keys={sorted(queue_payload.keys()) if queue_payload else []}, error={queue['error'] or 'none'}",
)

metrics = request("GET", "/health/metrics")
artifacts["metrics"] = {k: v for k, v in metrics.items() if k != "body"}
metrics_body = metrics.get("body", "")
metrics_ok = metrics["ok"] and (
    "blogsnap_http_requests_total" in metrics_body
    or "blogsnap_http_request_duration_seconds" in metrics_body
    or "python_info" in metrics_body
)
add_check(
    "metrics_endpoint",
    metrics_required,
    metrics_ok,
    f"status_code={metrics['status_code']}, has_expected_metric={metrics_ok}, error={metrics['error'] or 'none'}",
)

worker_detail = "docker compose not checked"
worker_passed = True
try:
    docker = subprocess.run(
        ["docker", "compose", "-f", "docker-compose.dev.yml", "ps", "worker"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        check=False,
    )
    output = f"{docker.stdout}\n{docker.stderr}".strip()
    lower_output = output.lower()
    worker_passed = docker.returncode == 0 and ("running" in lower_output or "up" in lower_output)
    worker_detail = output.splitlines()[-1] if output else f"docker_return_code={docker.returncode}"
except Exception as exc:
    worker_passed = False
    worker_detail = f"{type(exc).__name__}: {exc}"
add_check(
    "worker_container_running",
    worker_check_required,
    worker_passed,
    worker_detail,
    category="runtime",
)

required_failed = [check for check in checks if check["required"] and check["status"] != "pass"]
optional_failed = [check for check in checks if not check["required"] and check["status"] != "pass"]

if required_failed:
    smoke_status = "failed"
elif optional_failed:
    smoke_status = "needs_attention"
else:
    smoke_status = "ready"

next_actions = []
if required_failed:
    next_actions.append("Fix required smoke check failures before treating the deployment as healthy.")
    if any(check["name"] in {"api_health", "api_readiness"} for check in required_failed):
        next_actions.append("Confirm the API process is running and API_URL points to the deployed target.")
    if any(check["name"] == "metrics_endpoint" for check in required_failed):
        next_actions.append("Enable metrics or rerun with METRICS_REQUIRED=no if metrics are intentionally disabled.")
elif optional_failed:
    next_actions.append("Review optional smoke warnings and decide whether they should become required for this target.")
else:
    next_actions.append("Continue to post-launch monitoring and incident watch review.")

payload = {
    "status": "ok",
    "smoke_status": smoke_status,
    "generated_at_utc": ts,
    "api_url": api_url,
    "strict": strict,
    "metrics_required": metrics_required,
    "worker_check_required": worker_check_required,
    "git": {
        "branch": current_branch,
        "commit": current_commit,
    },
    "day59": {
        "path": str(day59_path),
        "verification_status": day59.get("verification_status"),
        "post_deploy_state": day59.get("post_deploy_state"),
        "branch": day59_branch,
        "commit": day59_commit,
    },
    "checks": checks,
    "required_failed": required_failed,
    "optional_failed": optional_failed,
    "artifacts": artifacts,
    "next_actions": next_actions,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "",
    "## Smoke Status",
    f"- smoke_status: {smoke_status}",
    f"- api_url: {api_url}",
    f"- git_branch: {current_branch}",
    f"- git_commit: {current_commit}",
    f"- day59_verification_status: {day59.get('verification_status', 'missing')}",
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
        "- Default mode writes a report even when smoke checks fail.",
        "- Use SMOKE_STRICT=yes to return a non-zero exit code when smoke_status is not ready.",
        "",
        "[OK] Day60 post-deploy smoke report generated",
    ]
)

with out_md.open("a", encoding="utf-8") as f:
    f.write("\n".join(lines))
    f.write("\n")

PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day60 post-deploy smoke report generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"

SMOKE_STATUS="$(python3 - <<'PY' "$OUT_JSON"
import json
import sys
from pathlib import Path

print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("smoke_status", "unknown"))
PY
)"

if [[ "$SMOKE_STRICT" == "yes" && "$SMOKE_STATUS" != "ready" ]]; then
  echo "[ERROR] Day60 smoke_status=$SMOKE_STATUS"
  exit 2
fi
