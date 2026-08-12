#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

API_URL="${API_URL:-http://127.0.0.1:8000}"
FRONTEND_URL="${FRONTEND_URL:-http://127.0.0.1:5173}"
UAT_TESTER="${UAT_TESTER:-$(git config user.name || true)}"
UAT_SCOPE="${UAT_SCOPE:-full-preview-flow}"
UAT_STRICT="${UAT_STRICT:-no}"
REFRESH_DAY61="${REFRESH_DAY61:-yes}"
export UAT_TESTER UAT_SCOPE

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day62-uat-session-$TS.md"
OUT_JSON="$OUT_DIR/day62-uat-session-$TS.json"
LATEST_MD="$OUT_DIR/day62-uat-session-latest.md"
LATEST_JSON="$OUT_DIR/day62-uat-session-latest.json"

DAY61_JSON="$OUT_DIR/day61-preview-readiness-latest.json"

echo "# Day62 UAT Session Packet" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- tester: ${UAT_TESTER:-unknown}" >> "$OUT_MD"
echo "- scope: $UAT_SCOPE" >> "$OUT_MD"
echo "- frontend_url: $FRONTEND_URL" >> "$OUT_MD"
echo "- api_url: $API_URL" >> "$OUT_MD"
echo "- uat_strict: $UAT_STRICT" >> "$OUT_MD"
echo "" >> "$OUT_MD"

if [[ "$REFRESH_DAY61" == "yes" ]]; then
  echo "[STEP] Refresh Day61 preview readiness"
  API_URL="$API_URL" \
    FRONTEND_URL="$FRONTEND_URL" \
    PREVIEW_STRICT=no \
    ./scripts/day61_preview_readiness_check.sh "$REPORT_DIR" "$OUT_DIR" >> "$OUT_MD"
else
  echo "[INFO] REFRESH_DAY61=no; using existing Day61 latest if present" >> "$OUT_MD"
fi

python3 - <<'PY' "$DAY61_JSON" "$OUT_JSON" "$OUT_MD" "$TS"
import json
import os
import subprocess
import sys
from pathlib import Path

day61_path = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
ts = sys.argv[4]

frontend_url = os.environ.get("FRONTEND_URL", "http://127.0.0.1:5173").rstrip("/")
api_url = os.environ.get("API_URL", "http://127.0.0.1:8000").rstrip("/")
tester = os.environ.get("UAT_TESTER", "").strip() or "unknown"
scope = os.environ.get("UAT_SCOPE", "full-preview-flow")
strict = os.environ.get("UAT_STRICT", "no").lower() == "yes"

current_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
current_branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()

checks = []


def add_check(name, required, passed, detail):
    checks.append(
        {
            "name": name,
            "required": required,
            "status": "pass" if passed else "fail",
            "detail": detail,
        }
    )


day61 = {}
if day61_path.exists():
    day61 = json.loads(day61_path.read_text(encoding="utf-8"))

day61_status = day61.get("preview_status", "missing")
day61_commit = day61.get("git", {}).get("commit", "")
day61_branch = day61.get("git", {}).get("branch", "")

add_check(
    "day61_preview_ready",
    True,
    day61_status == "ready",
    f"preview_status={day61_status}",
)
add_check(
    "day61_commit_matches_head",
    True,
    day61_commit == current_commit,
    f"day61_commit={day61_commit or 'missing'}, head={current_commit}",
)
add_check(
    "day61_branch_matches_current",
    True,
    day61_branch == current_branch,
    f"day61_branch={day61_branch or 'missing'}, branch={current_branch}",
)

operator_urls = day61.get("operator_urls", {})
add_check(
    "operator_urls_present",
    True,
    bool(operator_urls.get("open_preview")) and bool(operator_urls.get("api_health")),
    f"open_preview={operator_urls.get('open_preview', '')}, api_health={operator_urls.get('api_health', '')}",
)

frontend_readme = Path("frontend/README.md")
root_readme = Path("README.md")
frontend_text = frontend_readme.read_text(encoding="utf-8") if frontend_readme.exists() else ""
root_text = root_readme.read_text(encoding="utf-8") if root_readme.exists() else ""
add_check(
    "manual_preview_docs_present",
    True,
    "http://localhost:5173/" in frontend_text and "http://localhost:5173/" in root_text,
    "frontend and root README should both show the preview URL",
)

manual_steps = [
    {
        "id": "uat-01",
        "title": "Open web preview",
        "action": f"Open {frontend_url}/ in the browser.",
        "expected": "BlogSnap frontend page is visible, not the backend Not Found page.",
    },
    {
        "id": "uat-02",
        "title": "Login",
        "action": "Use the default demo email or a tester email, then click 로그인.",
        "expected": "Result message says login completed and project controls become usable.",
    },
    {
        "id": "uat-03",
        "title": "Create or select project",
        "action": "Create a project named Day62 UAT Project or select an existing project.",
        "expected": "Project is selected and no auth error appears.",
    },
    {
        "id": "uat-04",
        "title": "Configure draft request",
        "action": "Choose 글 종류, enter a keyword, select 2 or 3 drafts, and choose a sentiment level.",
        "expected": "The sentiment helper text changes to match the selected tone.",
    },
    {
        "id": "uat-05",
        "title": "Generate drafts",
        "action": "Click 초고 생성 + 작업 실행.",
        "expected": "2 or 3 drafts appear in the draft list.",
    },
    {
        "id": "uat-06",
        "title": "Regenerate draft",
        "action": "Click 다른 방향 재생성 on one draft.",
        "expected": "Draft list refreshes and the result message confirms regeneration.",
    },
    {
        "id": "uat-07",
        "title": "Select draft",
        "action": "Click 이 초고 선택 on the preferred draft.",
        "expected": "Selected draft is highlighted and result message confirms selection.",
    },
    {
        "id": "uat-08",
        "title": "Publish selected draft",
        "action": "Click 선택 초고 자동 업로드.",
        "expected": "Publish result JSON appears with status and a mock post URL in mock mode.",
    },
    {
        "id": "uat-09",
        "title": "Check API health/docs if confused",
        "action": f"Open {api_url}/health or {api_url}/docs.",
        "expected": "Health returns status ok; API docs render. Backend root may still show Not Found.",
    },
]

issue_template = {
    "title": "[UAT] ",
    "fields": [
        "Tester",
        "Time",
        "Browser",
        "Step ID",
        "Expected Result",
        "Actual Result",
        "Screenshot/Screen Recording",
        "Console or Network Error",
        "Severity: blocker/high/medium/low",
    ],
}

required_failed = [check for check in checks if check["required"] and check["status"] != "pass"]
optional_failed = [check for check in checks if not check["required"] and check["status"] != "pass"]

if required_failed:
    uat_status = "blocked"
elif optional_failed:
    uat_status = "needs_attention"
else:
    uat_status = "ready"

next_actions = []
if uat_status == "blocked":
    next_actions.append("Fix failed readiness checks before starting manual UAT.")
    if day61_status != "ready":
        next_actions.append("Run Day61 preview readiness and confirm preview_status is ready.")
else:
    next_actions.append("Start manual UAT from uat-01 using the web preview URL.")
    next_actions.append("Record any issue with the included issue template.")

payload = {
    "status": "ok",
    "uat_status": uat_status,
    "generated_at_utc": ts,
    "tester": tester,
    "scope": scope,
    "frontend_url": f"{frontend_url}/",
    "api_url": api_url,
    "strict": strict,
    "git": {
        "branch": current_branch,
        "commit": current_commit,
    },
    "day61": {
        "path": str(day61_path),
        "preview_status": day61_status,
        "branch": day61_branch,
        "commit": day61_commit,
    },
    "checks": checks,
    "required_failed": required_failed,
    "optional_failed": optional_failed,
    "manual_steps": manual_steps,
    "issue_template": issue_template,
    "next_actions": next_actions,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "",
    "## UAT Status",
    f"- uat_status: {uat_status}",
    f"- tester: {tester}",
    f"- scope: {scope}",
    f"- frontend_url: {frontend_url}/",
    f"- api_health: {api_url}/health",
    f"- api_docs: {api_url}/docs",
    f"- git_branch: {current_branch}",
    f"- git_commit: {current_commit}",
    f"- day61_preview_status: {day61_status}",
    "",
    "## Readiness Checks",
]
for check in checks:
    marker = "PASS" if check["status"] == "pass" else "FAIL"
    required_label = "required" if check["required"] else "optional"
    lines.append(f"- {marker}: {check['name']} ({required_label}) - {check['detail']}")

lines.extend(
    [
        "",
        "## Manual UAT Steps",
    ]
)
for step in manual_steps:
    lines.append(f"- [{step['id']}] {step['title']}: {step['action']} Expected: {step['expected']}")

lines.extend(
    [
        "",
        "## Issue Template",
        "```md",
        "### [UAT] <short title>",
        "- Tester:",
        "- Time:",
        "- Browser:",
        "- Step ID:",
        "- Expected Result:",
        "- Actual Result:",
        "- Screenshot/Screen Recording:",
        "- Console or Network Error:",
        "- Severity: blocker/high/medium/low",
        "```",
        "",
        "## Next Actions",
    ]
)
for action in next_actions:
    lines.append(f"- {action}")

lines.extend(
    [
        "",
        "## Operator Notes",
        "- Use this packet as the manual test script for the next user-facing preview test.",
        "- Keep API checks separate from product UI checks: product UI is the frontend URL.",
        "- Use UAT_STRICT=yes to return a non-zero exit code when uat_status is not ready.",
        "",
        "[OK] Day62 UAT session packet generated",
    ]
)

with out_md.open("a", encoding="utf-8") as f:
    f.write("\n".join(lines))
    f.write("\n")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day62 UAT session packet generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"

UAT_STATUS="$(python3 - <<'PY' "$OUT_JSON"
import json
import sys
from pathlib import Path

print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("uat_status", "unknown"))
PY
)"

if [[ "$UAT_STRICT" == "yes" && "$UAT_STATUS" != "ready" ]]; then
  echo "[ERROR] Day62 uat_status=$UAT_STATUS"
  exit 2
fi
