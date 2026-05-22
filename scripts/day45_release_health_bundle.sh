#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/release-health-$TS.md"
OUT_JSON="$OUT_DIR/release-health-$TS.json"
LATEST_MD="$OUT_DIR/release-health-latest.md"
LATEST_JSON="$OUT_DIR/release-health-latest.json"

pick_latest() {
  local pattern="$1"
  ls -1 "$REPORT_DIR"/$pattern 2>/dev/null | sort | tail -n1 || true
}

extract_status_line() {
  local path="$1"
  local line
  line="$(grep -E '^\[OK\]|FAILED|passed|completed' "$path" | tail -n1 || true)"
  if [[ -z "$line" ]]; then
    line="(status line not found)"
  fi
  echo "$line"
}

LATEST_D42="$(pick_latest "day42-go-live-*.md")"
LATEST_D43="$(pick_latest "day43-post-launch-*.md")"
LATEST_D44="$(pick_latest "day44-stabilization-trend-*.md")"
LATEST_D41="$(pick_latest "day41-gameday-*.md")"
LATEST_MON="$(pick_latest "monitoring-tuning-*.md")"

if [[ -z "$LATEST_D42" || ! -f "$LATEST_D42" ]]; then
  echo "[ERROR] missing day42 report"
  exit 1
fi
if [[ -z "$LATEST_D43" || ! -f "$LATEST_D43" ]]; then
  echo "[ERROR] missing day43 report"
  exit 1
fi
if [[ -z "$LATEST_D44" || ! -f "$LATEST_D44" ]]; then
  echo "[ERROR] missing day44 report"
  exit 1
fi

STATUS_D42="$(extract_status_line "$LATEST_D42")"
STATUS_D43="$(extract_status_line "$LATEST_D43")"
STATUS_D44="$(extract_status_line "$LATEST_D44")"
STATUS_D41=""
STATUS_MON=""

if [[ -n "$LATEST_D41" ]]; then
  STATUS_D41="$(extract_status_line "$LATEST_D41")"
fi
if [[ -n "$LATEST_MON" ]]; then
  STATUS_MON="$(extract_status_line "$LATEST_MON")"
fi

OVERALL="ok"
for s in "$STATUS_D42" "$STATUS_D43" "$STATUS_D44" "$STATUS_D41" "$STATUS_MON"; do
  if [[ "$s" == *"FAILED"* || "$s" == *"failed"* ]]; then
    OVERALL="needs_attention"
    break
  fi
done

{
  echo "# Release Health Bundle"
  echo ""
  echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "- overall: $OVERALL"
  echo ""
  echo "## Latest Reports"
  echo "- day42_go_live: $LATEST_D42"
  echo "- day43_post_launch: $LATEST_D43"
  echo "- day44_stabilization: $LATEST_D44"
  echo "- day41_gameday: ${LATEST_D41:-N/A}"
  echo "- monitoring_tuning: ${LATEST_MON:-N/A}"
  echo ""
  echo "## Status"
  echo "- day42: $STATUS_D42"
  echo "- day43: $STATUS_D43"
  echo "- day44: $STATUS_D44"
  if [[ -n "$STATUS_D41" ]]; then
    echo "- day41: $STATUS_D41"
  fi
  if [[ -n "$STATUS_MON" ]]; then
    echo "- monitoring: $STATUS_MON"
  fi
} > "$OUT_MD"

python3 - <<'PY' "$OUT_JSON" "$TS" "$OVERALL" \
  "$LATEST_D42" "$LATEST_D43" "$LATEST_D44" "$LATEST_D41" "$LATEST_MON" \
  "$STATUS_D42" "$STATUS_D43" "$STATUS_D44" "$STATUS_D41" "$STATUS_MON"
import json
import sys

out = sys.argv[1]
ts = sys.argv[2]
overall = sys.argv[3]

payload = {
    "generated_at_utc": ts,
    "overall": overall,
    "reports": {
        "day42_go_live": {"path": sys.argv[4], "status": sys.argv[9]},
        "day43_post_launch": {"path": sys.argv[5], "status": sys.argv[10]},
        "day44_stabilization": {"path": sys.argv[6], "status": sys.argv[11]},
        "day41_gameday": {"path": sys.argv[7], "status": sys.argv[12]},
        "monitoring_tuning": {"path": sys.argv[8], "status": sys.argv[13]},
    },
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
PY

cp "$OUT_MD" "$LATEST_MD"
cp "$OUT_JSON" "$LATEST_JSON"

echo "[OK] Day45 release health bundle generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
