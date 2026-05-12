#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-24}"

if [[ ! -d "$REPORT_DIR" ]]; then
  echo "[ERROR] report directory not found: $REPORT_DIR"
  exit 1
fi

latest_json="$(ls -1 "$REPORT_DIR"/release-candidate-gate-*.json 2>/dev/null | sort | tail -n1 || true)"
if [[ -z "$latest_json" ]]; then
  echo "[ERROR] no RC gate json report found in $REPORT_DIR"
  exit 1
fi

PYTHON_BIN="python3"
if command -v python3.11 >/dev/null 2>&1; then
  PYTHON_BIN="python3.11"
fi

"$PYTHON_BIN" - "$latest_json" "$MAX_AGE_HOURS" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
max_age_hours = int(sys.argv[2])

payload = json.loads(path.read_text(encoding="utf-8"))
status = payload.get("status")
steps = payload.get("steps", [])
ts = payload.get("generated_at_utc")

print(f"[INFO] latest report: {path}")
print(f"[INFO] status: {status}")

if not ts:
    print("[ERROR] generated_at_utc missing")
    sys.exit(1)

m = re.fullmatch(r"(\d{8})T(\d{6})Z", ts)
if not m:
    print(f"[ERROR] invalid generated_at_utc format: {ts}")
    sys.exit(1)

report_dt = datetime.strptime(ts, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
now = datetime.now(timezone.utc)
age_hours = (now - report_dt).total_seconds() / 3600.0
print(f"[INFO] report age hours: {age_hours:.2f}")

if age_hours > max_age_hours:
    print(f"[ERROR] report is stale (> {max_age_hours}h)")
    sys.exit(1)

if status != "passed":
    print("[ERROR] rc gate status is not passed")
    sys.exit(1)

bad_steps = [s for s in steps if s.get("result") not in ("passed", "skipped")]
if bad_steps:
    print("[ERROR] one or more steps failed")
    for s in bad_steps:
        print(f"  - {s.get('name')}: {s.get('result')}")
    sys.exit(1)

print("[OK] release decision gate passed")
PY
