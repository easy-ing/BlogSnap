#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

DEPLOY_TARGET="${DEPLOY_TARGET:-staging}"
DEPLOY_ACTION="${DEPLOY_ACTION:-dry-run}" # dry-run | execute
DEPLOY_OPERATOR="${DEPLOY_OPERATOR:-$(git config user.name || true)}"
CONFIRM_DEPLOY="${CONFIRM_DEPLOY:-no}"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day58-deployment-receipt-$TS.md"
OUT_JSON="$OUT_DIR/day58-deployment-receipt-$TS.json"
LATEST_MD="$OUT_DIR/day58-deployment-receipt-latest.md"
LATEST_JSON="$OUT_DIR/day58-deployment-receipt-latest.json"

EVIDENCE_JSON="$REPORT_DIR/day57-release-evidence-latest.json"

if [[ "$DEPLOY_ACTION" != "dry-run" && "$DEPLOY_ACTION" != "execute" ]]; then
  echo "[ERROR] invalid DEPLOY_ACTION: $DEPLOY_ACTION (allowed: dry-run|execute)"
  exit 1
fi

if [[ "$DEPLOY_ACTION" == "execute" && "$CONFIRM_DEPLOY" != "yes" ]]; then
  echo "[ERROR] DEPLOY_ACTION=execute requires CONFIRM_DEPLOY=yes"
  exit 1
fi

echo "# Day58 Deployment Execution Receipt" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "- deploy_target: $DEPLOY_TARGET" >> "$OUT_MD"
echo "- deploy_action: $DEPLOY_ACTION" >> "$OUT_MD"
echo "" >> "$OUT_MD"

echo "[STEP] Refresh Day57 release evidence"
./scripts/day57_release_evidence_index.sh "$REPORT_DIR" "$OUT_DIR" >> "$OUT_MD"

if [[ ! -f "$EVIDENCE_JSON" ]]; then
  echo "[ERROR] missing release evidence json: $EVIDENCE_JSON"
  exit 1
fi

python3 - <<'PY' "$EVIDENCE_JSON" "$OUT_JSON" "$OUT_MD" "$TS" "$DEPLOY_TARGET" "$DEPLOY_ACTION" "$DEPLOY_OPERATOR" "$CONFIRM_DEPLOY"
import json
import subprocess
import sys
from pathlib import Path

evidence_path = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
ts = sys.argv[4]
target = sys.argv[5]
action = sys.argv[6]
operator = sys.argv[7] or "unknown"
confirm = sys.argv[8]

evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
current_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
current_branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()

evidence_status = evidence.get("evidence_status", "missing")
evidence_commit = evidence.get("git", {}).get("commit", "")
evidence_branch = evidence.get("git", {}).get("branch", "")

reasons = []
if evidence_status != "ready":
    reasons.append(f"evidence_status is '{evidence_status}'")
if evidence_commit != current_commit:
    reasons.append("evidence commit does not match current HEAD")
if evidence_branch != current_branch:
    reasons.append("evidence branch does not match current branch")
if action == "execute" and confirm != "yes":
    reasons.append("execute action was not confirmed")

receipt_status = "ready" if not reasons else "blocked"
execution_state = "not_executed"
if receipt_status == "ready" and action == "dry-run":
    execution_state = "dry_run_recorded"
elif receipt_status == "ready" and action == "execute":
    execution_state = "execute_authorized"

payload = {
    "status": "ok",
    "receipt_status": receipt_status,
    "execution_state": execution_state,
    "generated_at_utc": ts,
    "deploy": {
        "target": target,
        "action": action,
        "operator": operator,
        "confirm_deploy": confirm,
    },
    "git": {
        "branch": current_branch,
        "commit": current_commit,
    },
    "evidence": {
        "path": str(evidence_path),
        "status": evidence_status,
        "branch": evidence_branch,
        "commit": evidence_commit,
    },
    "block_reasons": reasons,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "",
    "## Receipt Status",
    f"- receipt_status: {receipt_status}",
    f"- execution_state: {execution_state}",
    f"- operator: {operator}",
    f"- git_branch: {current_branch}",
    f"- git_commit: {current_commit}",
    "",
    "## Evidence",
    f"- path: {evidence_path}",
    f"- evidence_status: {evidence_status}",
    f"- evidence_branch: {evidence_branch}",
    f"- evidence_commit: {evidence_commit}",
    "",
    "## Block Reasons",
]
if reasons:
    lines.extend(f"- {reason}" for reason in reasons)
else:
    lines.append("- none")
lines.extend(
    [
        "",
        "## Execution Note",
        "- This receipt records approval context only. Production deployment must still be executed by the configured deployment system.",
        "",
        "[OK] Day58 deployment execution receipt generated",
    ]
)

with out_md.open("a", encoding="utf-8") as f:
    f.write("\n".join(lines))
    f.write("\n")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day58 deployment execution receipt generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
