#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day51-ops-status-$TS.md"
OUT_JSON="$OUT_DIR/day51-ops-status-$TS.json"
OUT_SVG="$OUT_DIR/day51-ops-status-$TS.svg"
LATEST_MD="$OUT_DIR/day51-ops-status-latest.md"
LATEST_JSON="$OUT_DIR/day51-ops-status-latest.json"
LATEST_SVG="$OUT_DIR/day51-ops-status-latest.svg"

LATEST_DAY50_JSON="$(ls -1 "$REPORT_DIR"/day50-ops-suite-*.json 2>/dev/null | sort | tail -n1 || true)"
if [[ -z "$LATEST_DAY50_JSON" || ! -f "$LATEST_DAY50_JSON" ]]; then
  echo "[ERROR] missing day50 ops suite json"
  exit 1
fi

python3 - <<'PY' "$LATEST_DAY50_JSON" "$OUT_JSON" "$OUT_MD" "$OUT_SVG"
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

src = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
out_svg = Path(sys.argv[4])

data = json.loads(src.read_text(encoding="utf-8"))
suite_status = str(data.get("status", "unknown")).lower()
steps = data.get("steps", [])
total = len(steps)
passed = sum(1 for s in steps if s.get("result") == "passed")

if suite_status == "passed":
    badge_label = "ops-suite"
    badge_value = "passed"
    color = "#2ea043"
    overall = "healthy"
else:
    badge_label = "ops-suite"
    badge_value = "attention"
    color = "#d29922"
    overall = "needs_attention"

generated = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

payload = {
    "status": "ok",
    "overall": overall,
    "generated_at_utc": generated,
    "source_day50_json": str(src),
    "summary": {
        "suite_status": suite_status,
        "steps_total": total,
        "steps_passed": passed,
    },
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

md_lines = [
    "# Day51 Ops Status",
    "",
    f"- generated_at_utc: {generated}",
    f"- source_day50_json: {src}",
    f"- overall: {overall}",
    f"- suite_status: {suite_status}",
    f"- steps_passed: {passed}/{total}",
    "",
    "[OK] Day51 ops status badge generated",
]
out_md.write_text("\n".join(md_lines), encoding="utf-8")

# Simple static SVG badge (left+right)
label = badge_label
value = badge_value
label_w = max(52, 7 * len(label) + 12)
value_w = max(52, 7 * len(value) + 12)
width = label_w + value_w

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="20" role="img" aria-label="{label}: {value}">
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="r">
    <rect width="{width}" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#r)">
    <rect width="{label_w}" height="20" fill="#555"/>
    <rect x="{label_w}" width="{value_w}" height="20" fill="{color}"/>
    <rect width="{width}" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
    <text x="{label_w/2:.1f}" y="15">{label}</text>
    <text x="{label_w + value_w/2:.1f}" y="15">{value}</text>
  </g>
</svg>
'''
out_svg.write_text(svg, encoding="utf-8")
PY

cp "$OUT_MD" "$LATEST_MD"
cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_SVG" "$LATEST_SVG"

echo "[OK] Day51 ops status badge generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] svg: $OUT_SVG"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
echo "[INFO] latest svg: $LATEST_SVG"
