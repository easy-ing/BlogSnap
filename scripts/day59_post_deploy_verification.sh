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

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day59-post-deploy-verification-$TS.md"
OUT_JSON="$OUT_DIR/day59-post-deploy-verification-$TS.json"
LATEST_MD="$OUT_DIR/day59-post-deploy-verification-latest.md"
LATEST_JSON="$OUT_DIR/day59-post-deploy-verification-latest.json"

RECEIPT_JSON="$OUT_DIR/day58-deployment-receipt-latest.json"

echo "# Day59 Post-Deploy Verification" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- deploy_target: $DEPLOY_TARGET" >> "$OUT_MD"
echo "- deploy_action: $DEPLOY_ACTION" >> "$OUT_MD"
echo "" >> "$OUT_MD"

echo "[STEP] Refresh Day58 deployment execution receipt"
DEPLOY_TARGET="$DEPLOY_TARGET" \
  DEPLOY_ACTION="$DEPLOY_ACTION" \
  CONFIRM_DEPLOY="$CONFIRM_DEPLOY" \
  ./scripts/day58_deployment_execution_receipt.sh "$REPORT_DIR" "$OUT_DIR" >> "$OUT_MD"

if [[ ! -f "$RECEIPT_JSON" ]]; then
  echo "[ERROR] missing deployment receipt json: $RECEIPT_JSON"
  exit 1
fi

python3 - <<'PY' "$RECEIPT_JSON" "$OUT_JSON" "$OUT_MD" "$TS" "$DEPLOY_TARGET" "$DEPLOY_ACTION"
import json
import subprocess
import sys
from pathlib import Path

receipt_path = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
ts = sys.argv[4]
target = sys.argv[5]
action = sys.argv[6]

receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
current_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
current_branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()

receipt_status = receipt.get("receipt_status", "missing")
execution_state = receipt.get("execution_state", "missing")
receipt_commit = receipt.get("git", {}).get("commit", "")
receipt_branch = receipt.get("git", {}).get("branch", "")
receipt_target = receipt.get("deploy", {}).get("target", "")
receipt_action = receipt.get("deploy", {}).get("action", "")
evidence_status = receipt.get("evidence", {}).get("status", "missing")
evidence_commit = receipt.get("evidence", {}).get("commit", "")
evidence_branch = receipt.get("evidence", {}).get("branch", "")

expected_states = {
    "dry-run": "dry_run_recorded",
    "execute": "execute_authorized",
}

checks = []

def add_check(name, passed, detail):
    checks.append(
        {
            "name": name,
            "status": "pass" if passed else "fail",
            "detail": detail,
        }
    )

add_check(
    "receipt_ready",
    receipt_status == "ready",
    f"receipt_status={receipt_status}",
)
add_check(
    "execution_state_matches_action",
    execution_state == expected_states.get(action),
    f"execution_state={execution_state}, expected={expected_states.get(action)}",
)
add_check(
    "receipt_commit_matches_head",
    receipt_commit == current_commit,
    f"receipt_commit={receipt_commit}, head={current_commit}",
)
add_check(
    "receipt_branch_matches_current",
    receipt_branch == current_branch,
    f"receipt_branch={receipt_branch}, branch={current_branch}",
)
add_check(
    "receipt_target_matches_request",
    receipt_target == target,
    f"receipt_target={receipt_target}, requested_target={target}",
)
add_check(
    "receipt_action_matches_request",
    receipt_action == action,
    f"receipt_action={receipt_action}, requested_action={action}",
)
add_check(
    "evidence_ready",
    evidence_status == "ready",
    f"evidence_status={evidence_status}",
)
add_check(
    "evidence_commit_matches_head",
    evidence_commit == current_commit,
    f"evidence_commit={evidence_commit}, head={current_commit}",
)
add_check(
    "evidence_branch_matches_current",
    evidence_branch == current_branch,
    f"evidence_branch={evidence_branch}, branch={current_branch}",
)

failed = [check for check in checks if check["status"] != "pass"]
verification_status = "ready" if not failed else "needs_attention"

if verification_status == "ready" and action == "dry-run":
    post_deploy_state = "dry_run_verified"
elif verification_status == "ready" and action == "execute":
    post_deploy_state = "execute_receipt_verified"
else:
    post_deploy_state = "blocked"

next_actions = []
if failed:
    next_actions.append("Fix failed checks and rerun Day59 before moving to deployment monitoring.")
elif action == "dry-run":
    next_actions.append("For real deployment, rerun with DEPLOY_ACTION=execute CONFIRM_DEPLOY=yes.")
    next_actions.append("After execution, rerun Day59 and continue with post-launch monitoring.")
else:
    next_actions.append("Continue with post-launch monitoring and incident watch reports.")

payload = {
    "status": "ok",
    "verification_status": verification_status,
    "post_deploy_state": post_deploy_state,
    "generated_at_utc": ts,
    "deploy": {
        "target": target,
        "action": action,
    },
    "git": {
        "branch": current_branch,
        "commit": current_commit,
    },
    "receipt": {
        "path": str(receipt_path),
        "status": receipt_status,
        "execution_state": execution_state,
        "branch": receipt_branch,
        "commit": receipt_commit,
        "target": receipt_target,
        "action": receipt_action,
    },
    "evidence": {
        "status": evidence_status,
        "branch": evidence_branch,
        "commit": evidence_commit,
    },
    "checks": checks,
    "failed_checks": failed,
    "next_actions": next_actions,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "",
    "## Verification Status",
    f"- verification_status: {verification_status}",
    f"- post_deploy_state: {post_deploy_state}",
    f"- git_branch: {current_branch}",
    f"- git_commit: {current_commit}",
    "",
    "## Receipt",
    f"- path: {receipt_path}",
    f"- receipt_status: {receipt_status}",
    f"- execution_state: {execution_state}",
    f"- receipt_branch: {receipt_branch}",
    f"- receipt_commit: {receipt_commit}",
    "",
    "## Checks",
]
for check in checks:
    lines.append(f"- {check['status']}: {check['name']} ({check['detail']})")

lines.append("")
lines.append("## Next Actions")
for action_item in next_actions:
    lines.append(f"- {action_item}")

lines.extend(
    [
        "",
        "## Operator Notes",
        "- Day59 verifies deployment receipt integrity only; it does not run application deployment.",
        "- If DEPLOY_ACTION=dry-run, treat this as a rehearsal verification package.",
        "",
        "[OK] Day59 post-deploy verification generated",
    ]
)

with out_md.open("a", encoding="utf-8") as f:
    f.write("\n".join(lines))
    f.write("\n")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day59 post-deploy verification generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
