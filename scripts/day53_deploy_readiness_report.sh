#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day53-deploy-readiness-$TS.md"
OUT_JSON="$OUT_DIR/day53-deploy-readiness-$TS.json"
LATEST_MD="$OUT_DIR/day53-deploy-readiness-latest.md"
LATEST_JSON="$OUT_DIR/day53-deploy-readiness-latest.json"
CHECK_LOG="$OUT_DIR/day53-deploy-check-$TS.log"

MANIFEST_JSON="$REPORT_DIR/day52-ops-manifest-latest.json"
APPROVAL_JSON="$REPORT_DIR/day48-deploy-approval-latest.json"
OPS_STATUS_JSON="$REPORT_DIR/day51-ops-status-latest.json"

set +e
./scripts/check_deploy_ready.sh > "$CHECK_LOG" 2>&1
CHECK_EXIT=$?
set -e

python3 - <<'PY' "$OUT_JSON" "$OUT_MD" "$CHECK_LOG" "$CHECK_EXIT" "$MANIFEST_JSON" "$APPROVAL_JSON" "$OPS_STATUS_JSON"
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

out_json = Path(sys.argv[1])
out_md = Path(sys.argv[2])
check_log = Path(sys.argv[3])
check_exit = int(sys.argv[4])
manifest_path = Path(sys.argv[5])
approval_path = Path(sys.argv[6])
ops_status_path = Path(sys.argv[7])

missing = [
    str(path)
    for path in (manifest_path, approval_path, ops_status_path)
    if not path.exists()
]

manifest = {}
approval = {}
ops_status = {}
if manifest_path.exists():
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
if approval_path.exists():
    approval = json.loads(approval_path.read_text(encoding="utf-8"))
if ops_status_path.exists():
    ops_status = json.loads(ops_status_path.read_text(encoding="utf-8"))

manifest_status = manifest.get("status", "missing")
approval_decision = approval.get("decision", "missing")
ops_overall = ops_status.get("overall", "missing")

block_reasons = []
if check_exit != 0:
    block_reasons.append("check_deploy_ready.sh failed")
if missing:
    block_reasons.append("required ops report json missing")
if manifest_status != "ok":
    block_reasons.append(f"ops manifest status is '{manifest_status}'")
if approval_decision != "approved":
    block_reasons.append(f"deploy approval decision is '{approval_decision}'")
if ops_overall != "healthy":
    block_reasons.append(f"ops status overall is '{ops_overall}'")

decision = "ready" if not block_reasons else "blocked"
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
check_output = check_log.read_text(encoding="utf-8", errors="replace") if check_log.exists() else ""

payload = {
    "status": "ok",
    "decision": decision,
    "generated_at_utc": generated_at,
    "signals": {
        "deploy_check_exit_code": check_exit,
        "ops_manifest_status": manifest_status,
        "deploy_approval_decision": approval_decision,
        "ops_status_overall": ops_overall,
    },
    "sources": {
        "deploy_check_log": str(check_log),
        "ops_manifest_json": str(manifest_path),
        "deploy_approval_json": str(approval_path),
        "ops_status_json": str(ops_status_path),
    },
    "missing": missing,
    "block_reasons": block_reasons,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "# Day53 Deploy Readiness Report",
    "",
    f"- generated_at_utc: {generated_at}",
    f"- decision: {decision}",
    f"- deploy_check_exit_code: {check_exit}",
    f"- ops_manifest_status: {manifest_status}",
    f"- deploy_approval_decision: {approval_decision}",
    f"- ops_status_overall: {ops_overall}",
    "",
    "## Sources",
    f"- deploy_check_log: {check_log}",
    f"- ops_manifest_json: {manifest_path}",
    f"- deploy_approval_json: {approval_path}",
    f"- ops_status_json: {ops_status_path}",
    "",
    "## Block Reasons",
]
if block_reasons:
    lines.extend(f"- {reason}" for reason in block_reasons)
else:
    lines.append("- none")

lines.extend(
    [
        "",
        "## Deploy Check Output",
        "```text",
        check_output.strip(),
        "```",
        "",
        "[OK] Day53 deploy readiness report generated",
    ]
)
out_md.write_text("\n".join(lines), encoding="utf-8")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day53 deploy readiness report generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
