#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RETENTION_HOURS="${1:-24}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_JSON_PATH="$REPORT_DIR/asset-cleanup-$TS.json"
REPORT_MD_PATH="$REPORT_DIR/asset-cleanup-$TS.md"

RUN_OUTPUT=$(./scripts/day30_asset_cleanup_run.sh "$RETENTION_HOURS")
PAYLOAD=$(echo "$RUN_OUTPUT" | awk '/^{.*}$/ {print; exit}')

if [ -z "$PAYLOAD" ]; then
  echo "[ERROR] cleanup payload json not found"
  echo "$RUN_OUTPUT"
  exit 1
fi

echo "$PAYLOAD" > "$REPORT_JSON_PATH"

python3.11 - <<'PY' "$REPORT_JSON_PATH" "$REPORT_MD_PATH" "$RETENTION_HOURS"
import json
import sys
from datetime import datetime, timezone

json_path = sys.argv[1]
md_path = sys.argv[2]
retention_hours = sys.argv[3]

with open(json_path, encoding="utf-8") as f:
    payload = json.load(f)

lines = [
    "# Asset Cleanup Report",
    "",
    f"- generated_at_utc: {datetime.now(timezone.utc).isoformat()}",
    f"- retention_hours: {retention_hours}",
    f"- status: {payload.get('status', 'unknown')}",
    f"- projects: {payload.get('projects', 0)}",
    f"- purged: {payload.get('purged', 0)}",
]

with open(md_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
PY

echo "[INFO] report json written: $REPORT_JSON_PATH"
echo "[INFO] report markdown written: $REPORT_MD_PATH"
echo "[INFO] report json payload: $PAYLOAD"
