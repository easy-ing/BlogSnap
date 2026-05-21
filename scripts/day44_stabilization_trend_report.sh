#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_PATH="$OUT_DIR/day44-stabilization-trend-$TS.md"

pick_latest() {
  local pattern="$1"
  ls -1 "$REPORT_DIR"/$pattern 2>/dev/null | sort | tail -n1 || true
}

require_file() {
  local path="$1"
  [[ -n "$path" && -f "$path" ]]
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
LATEST_D41="$(pick_latest "day41-gameday-*.md")"
LATEST_MON="$(pick_latest "monitoring-tuning-*.md")"

if ! require_file "$LATEST_D42"; then
  echo "[ERROR] missing day42 go-live report"
  exit 1
fi
if ! require_file "$LATEST_D43"; then
  echo "[ERROR] missing day43 post-launch report"
  exit 1
fi

{
  echo "# Day44 Stabilization Trend Report"
  echo ""
  echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "- report_dir: $REPORT_DIR"
  echo ""
  echo "## Latest Reports"
  echo "- day42_go_live: $LATEST_D42"
  echo "- day43_post_launch: $LATEST_D43"
  echo "- day41_gameday: ${LATEST_D41:-N/A}"
  echo "- monitoring_tuning: ${LATEST_MON:-N/A}"
  echo ""
  echo "## Status Snapshot"
  echo "- day42: $(extract_status_line "$LATEST_D42")"
  echo "- day43: $(extract_status_line "$LATEST_D43")"
  if [[ -n "$LATEST_D41" ]]; then
    echo "- day41: $(extract_status_line "$LATEST_D41")"
  fi
  if [[ -n "$LATEST_MON" ]]; then
    echo "- monitoring: $(extract_status_line "$LATEST_MON")"
  fi
  echo ""
  echo "## Recommendation"
  echo "1. day42/day43 결과가 모두 OK이면 운영 안정화 구간으로 간주"
  echo "2. FAILED 문자열이 있으면 즉시 Day41 runbook 기준 복구 리허설 재실행"
  echo "3. 다음 배포 전 Day42 gate 재실행 후 비교"
} > "$OUT_PATH"

echo "[OK] Day44 stabilization trend report generated"
echo "[INFO] report: $OUT_PATH"
