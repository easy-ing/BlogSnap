#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day57-release-evidence-$TS.md"
OUT_JSON="$OUT_DIR/day57-release-evidence-$TS.json"
LATEST_MD="$OUT_DIR/day57-release-evidence-latest.md"
LATEST_JSON="$OUT_DIR/day57-release-evidence-latest.json"

pick_latest() {
  local pattern="$1"
  ls -1 "$REPORT_DIR"/$pattern 2>/dev/null | sort | tail -n1 || true
}

echo "# Day57 Release Evidence Index" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "" >> "$OUT_MD"

echo "[STEP] Refresh Day56 handoff package"
./scripts/day56_release_handoff_package.sh "$REPORT_DIR" "$OUT_DIR" >> "$OUT_MD"

DAY53_JSON="$(pick_latest "day53-deploy-readiness-*.json")"
DAY55_JSON="$(pick_latest "day55-release-lock-*.json")"
DAY56_JSON="$(pick_latest "day56-release-handoff-*.json")"
DAY52_JSON="$(pick_latest "day52-ops-manifest-*.json")"
DAY51_JSON="$(pick_latest "day51-ops-status-*.json")"
DAY48_JSON="$(pick_latest "day48-deploy-approval-*.json")"
HEALTH_JSON="$REPORT_DIR/release-health-latest.json"

python3 - <<'PY' "$OUT_JSON" "$OUT_MD" \
  "$DAY53_JSON" "$DAY55_JSON" "$DAY56_JSON" "$DAY52_JSON" "$DAY51_JSON" "$DAY48_JSON" "$HEALTH_JSON"
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

out_json = Path(sys.argv[1])
out_md = Path(sys.argv[2])
labels = [
    "day53_deploy_readiness",
    "day55_release_lock",
    "day56_release_handoff",
    "day52_ops_manifest",
    "day51_ops_status",
    "day48_deploy_approval",
    "release_health_latest",
]
paths = [Path(raw) if raw else Path("") for raw in sys.argv[3:]]

head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

items = []
missing = []
for label, path in zip(labels, paths):
    exists = bool(str(path)) and path.exists()
    status = "missing"
    summary = {}
    if exists:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            summary = {
                "status": data.get("status"),
                "decision": data.get("decision"),
                "overall": data.get("overall"),
                "lock_status": data.get("lock_status"),
                "handoff_status": data.get("handoff_status"),
            }
            status = "present"
        except json.JSONDecodeError:
            status = "invalid_json"
    else:
        missing.append(label)

    items.append(
        {
            "label": label,
            "path": str(path) if str(path) else "",
            "status": status,
            "summary": {k: v for k, v in summary.items() if v is not None},
        }
    )

handoff = {}
if paths[2].exists():
    handoff = json.loads(paths[2].read_text(encoding="utf-8"))

handoff_status = handoff.get("handoff_status", "missing")
handoff_commit = handoff.get("git", {}).get("commit", "")
handoff_branch = handoff.get("git", {}).get("branch", "")
evidence_status = "ready"
reasons = []

if missing:
    evidence_status = "needs_attention"
    reasons.append(f"missing evidence: {', '.join(missing)}")
if handoff_status != "ready":
    evidence_status = "needs_attention"
    reasons.append(f"handoff status is '{handoff_status}'")
if handoff_commit != head:
    evidence_status = "needs_attention"
    reasons.append("handoff commit does not match HEAD")
if handoff_branch != branch:
    evidence_status = "needs_attention"
    reasons.append("handoff branch does not match current branch")

payload = {
    "status": "ok",
    "evidence_status": evidence_status,
    "generated_at_utc": generated_at,
    "git": {
        "branch": branch,
        "commit": head,
    },
    "evidence": items,
    "reasons": reasons,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

with out_md.open("a", encoding="utf-8") as f:
    f.write("\n## Evidence Status\n")
    f.write(f"- status: {evidence_status}\n")
    f.write(f"- git_branch: {branch}\n")
    f.write(f"- git_commit: {head}\n")
    if reasons:
        f.write("\n## Reasons\n")
        for reason in reasons:
            f.write(f"- {reason}\n")
    f.write("\n## Evidence Files\n")
    for item in items:
        f.write(f"- {item['label']}: {item['path'] or 'MISSING'} ({item['status']})\n")
    f.write("\n## Operator Notes\n")
    f.write("- Attach this evidence index with Day56 handoff for deployment approval.\n")
    f.write("- Re-run Day57 after any new commit before final deployment.\n")
    f.write("\n[OK] Day57 release evidence index generated\n")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day57 release evidence index generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
