#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RETENTION_HOURS="${1:-24}"
REPORT_DIR="${2:-tmp/reports}"
mkdir -p "$REPORT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
REPORT_PATH="$REPORT_DIR/asset-cleanup-$TS.json"

PAYLOAD=$(./scripts/day30_asset_cleanup_run.sh "$RETENTION_HOURS" | tail -n 2 | head -n 1)

echo "$PAYLOAD" > "$REPORT_PATH"
echo "[INFO] report written: $REPORT_PATH"
