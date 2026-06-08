#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT_DIR="${1:-tmp/reports}"
OUT_DIR="${2:-tmp/reports}"
mkdir -p "$OUT_DIR"

TS="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_MD="$OUT_DIR/day55-release-lock-$TS.md"
OUT_JSON="$OUT_DIR/day55-release-lock-$TS.json"
LATEST_MD="$OUT_DIR/day55-release-lock-latest.md"
LATEST_JSON="$OUT_DIR/day55-release-lock-latest.json"

READINESS_JSON="$REPORT_DIR/day53-deploy-readiness-latest.json"

if [[ ! -f "$READINESS_JSON" ]]; then
  echo "[ERROR] missing readiness json: $READINESS_JSON"
  exit 1
fi

GIT_COMMIT="$(git rev-parse HEAD)"
GIT_BRANCH="$(git branch --show-current)"

python3 - <<'PY' "$READINESS_JSON" "$OUT_JSON" "$OUT_MD" "$TS" "$GIT_COMMIT" "$GIT_BRANCH"
import hashlib
import json
import sys
from pathlib import Path

readiness_path = Path(sys.argv[1])
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
ts = sys.argv[4]
git_commit = sys.argv[5]
git_branch = sys.argv[6]

readiness = json.loads(readiness_path.read_text(encoding="utf-8"))
decision = readiness.get("decision", "missing")
block_reasons = readiness.get("block_reasons", [])
sources = readiness.get("sources", {})

def sha256_file(path: Path) -> str:
    if not path.exists():
        return ""
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

source_items = {}
for key, raw_path in sources.items():
    path = Path(raw_path)
    source_items[key] = {
        "path": raw_path,
        "exists": path.exists(),
        "sha256": sha256_file(path),
    }

lock_status = "locked" if decision == "ready" and not block_reasons else "blocked"

payload = {
    "status": "ok",
    "lock_status": lock_status,
    "generated_at_utc": ts,
    "git": {
        "branch": git_branch,
        "commit": git_commit,
    },
    "readiness": {
        "path": str(readiness_path),
        "decision": decision,
        "block_reasons": block_reasons,
        "sha256": sha256_file(readiness_path),
    },
    "sources": source_items,
}

out_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "# Day55 Release Lock Snapshot",
    "",
    f"- generated_at_utc: {ts}",
    f"- lock_status: {lock_status}",
    f"- git_branch: {git_branch}",
    f"- git_commit: {git_commit}",
    f"- readiness_decision: {decision}",
    "",
    "## Readiness",
    f"- path: {readiness_path}",
    f"- sha256: {payload['readiness']['sha256']}",
    "",
    "## Sources",
]
for key, item in source_items.items():
    lines.append(f"- {key}: {item['path']} ({'exists' if item['exists'] else 'missing'}, sha256={item['sha256'] or 'N/A'})")

lines.append("")
lines.append("## Block Reasons")
if block_reasons:
    lines.extend(f"- {reason}" for reason in block_reasons)
else:
    lines.append("- none")

lines.append("")
lines.append("[OK] Day55 release lock snapshot generated")

out_md.write_text("\n".join(lines), encoding="utf-8")

if lock_status != "locked":
    sys.exit(2)
PY

cp "$OUT_JSON" "$LATEST_JSON"
cp "$OUT_MD" "$LATEST_MD"

echo "[OK] Day55 release lock snapshot generated"
echo "[INFO] markdown: $OUT_MD"
echo "[INFO] json: $OUT_JSON"
echo "[INFO] latest markdown: $LATEST_MD"
echo "[INFO] latest json: $LATEST_JSON"
