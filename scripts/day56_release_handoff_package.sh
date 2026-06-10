#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day56-release-handoff-$TS.md"
OUT_JSON="$OUT_DIR/day56-release-handoff-$TS.json"
LATEST_MD="$OUT_DIR/day56-release-handoff-latest.md"
LATEST_JSON="$OUT_DIR/day56-release-handoff-latest.json"

echo "# Day56 Release Handoff Package" > "$OUT_MD"
echo "" >> "$OUT_MD"
echo "- generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$OUT_MD"
echo "" >> "$OUT_MD"

echo "[STEP] Refresh release lock snapshot"
./scripts/day55_release_lock_snapshot.sh "$REPORT_DIR" "$OUT_DIR" >> "$OUT_MD"

LOCK_JSON="$OUT_DIR/day55-release-lock-latest.json"
if [[ ! -f "$LOCK_JSON" ]]; then
  echo "[ERROR] missing release lock json: $LOCK_JSON"
  exit 1
fi

python3 - <<'PY' "$LOCK_JSON" "$OUT_JSON" "$OUT_MD"
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

lock_path = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])

lock = json.loads(lock_path.read_text(encoding="utf-8"))
current_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
current_branch = subprocess.check_output(["git", "branch", "--show-current"], text=True).strip()

def sha256_file(path: Path) -> str:
    if not path.exists():
        return ""
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

lock_status = lock.get("lock_status", "missing")
lock_git = lock.get("git", {})
lock_commit = lock_git.get("commit", "")
lock_branch = lock_git.get("branch", "")

checks = []
checks.append(
    {
        "name": "lock_status_locked",
        "passed": lock_status == "locked",
        "detail": lock_status,
    }
)
checks.append(
    {
        "name": "lock_commit_matches_head",
        "passed": lock_commit == current_commit,
        "detail": f"lock={lock_commit} head={current_commit}",
    }
)
checks.append(
    {
        "name": "lock_branch_matches_current",
        "passed": lock_branch == current_branch,
        "detail": f"lock={lock_branch} current={current_branch}",
    }
)

readiness = lock.get("readiness", {})
readiness_path = Path(readiness.get("path", ""))
checks.append(
    {
        "name": "readiness_checksum_matches",
        "passed": readiness_path.exists() and sha256_file(readiness_path) == readiness.get("sha256", ""),
        "detail": str(readiness_path),
    }
)

for key, source in lock.get("sources", {}).items():
    path = Path(source.get("path", ""))
    checks.append(
        {
            "name": f"source_checksum_matches:{key}",
            "passed": path.exists() and sha256_file(path) == source.get("sha256", ""),
            "detail": str(path),
        }
    )

handoff_status = "ready" if all(item["passed"] for item in checks) else "needs_attention"
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

payload = {
    "status": "ok",
    "handoff_status": handoff_status,
    "generated_at_utc": generated_at,
    "release_lock_json": str(lock_path),
    "git": {
        "branch": current_branch,
        "commit": current_commit,
    },
    "checks": checks,
}
out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

with out_md.open("a", encoding="utf-8") as f:
    f.write("\n## Handoff Status\n")
    f.write(f"- status: {handoff_status}\n")
    f.write(f"- git_branch: {current_branch}\n")
    f.write(f"- git_commit: {current_commit}\n")
    f.write(f"- release_lock_json: {lock_path}\n")
    f.write("\n## Verification Checks\n")
    for item in checks:
        marker = "[x]" if item["passed"] else "[ ]"
        f.write(f"- {marker} {item['name']}: {item['detail']}\n")
    f.write("\n## Release Handoff Notes\n")
    f.write("- Attach this package with the Day55 lock snapshot for deployment approval.\n")
    f.write("- Re-run Day54 and Day55 if any verification check fails.\n")
    f.write("\n[OK] Day56 release handoff package generated\n")
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day56 release handoff package generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
