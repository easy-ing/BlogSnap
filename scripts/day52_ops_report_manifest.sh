#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_JSON="$OUT_DIR/day52-ops-manifest-$TS.json"
OUT_MD="$OUT_DIR/day52-ops-manifest-$TS.md"
LATEST_JSON="$OUT_DIR/day52-ops-manifest-latest.json"
LATEST_MD="$OUT_DIR/day52-ops-manifest-latest.md"

python3 - <<'PY' "$REPORT_DIR" "$OUT_JSON" "$OUT_MD"
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

report_dir = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])

patterns = {
    "day45_release_health": r"release-health-\d{8}T\d{6}Z\.json$",
    "day46_alert_noise": r"day46-alert-noise-review-\d{8}T\d{6}Z\.json$",
    "day47_incident_summary": r"day47-incident-summary-\d{8}T\d{6}Z\.json$",
    "day48_deploy_approval": r"day48-deploy-approval-\d{8}T\d{6}Z\.json$",
    "day49_retro_autofill": r"day49-retro-autofill-\d{8}T\d{6}Z\.json$",
    "day50_ops_suite": r"day50-ops-suite-\d{8}T\d{6}Z\.json$",
    "day51_ops_status": r"day51-ops-status-\d{8}T\d{6}Z\.json$",
}

all_files = sorted([p for p in report_dir.glob("*.json")], key=lambda p: p.name)

def latest_matching(regex: str):
    pat = re.compile(regex)
    matches = [p for p in all_files if pat.search(p.name)]
    return matches[-1] if matches else None

manifest = {}
missing = []
for key, regex in patterns.items():
    latest = latest_matching(regex)
    if latest:
        manifest[key] = str(latest)
    else:
        manifest[key] = ""
        missing.append(key)

status = "ok" if not missing else "partial"
payload = {
    "status": status,
    "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "report_dir": str(report_dir),
    "reports": manifest,
    "missing": missing,
}

out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "# Day52 Ops Report Manifest",
    "",
    f"- generated_at_utc: {payload['generated_at_utc']}",
    f"- status: {status}",
    f"- report_dir: {report_dir}",
    "",
    "## Latest Reports",
]
for key, path in manifest.items():
    lines.append(f"- {key}: {path if path else 'MISSING'}")

if missing:
    lines.append("")
    lines.append("## Missing")
    for item in missing:
        lines.append(f"- {item}")

lines.append("")
lines.append("[OK] Day52 ops manifest generated")

out_md.write_text("\n".join(lines), encoding="utf-8")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day52 ops manifest generated"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] latest json: $LATEST_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
