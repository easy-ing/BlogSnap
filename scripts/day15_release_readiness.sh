#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[INFO] Start postgres for readiness checks"
docker compose -f docker-compose.dev.yml up -d postgres >/tmp/day15_postgres.log 2>&1 || (cat /tmp/day15_postgres.log && exit 1)

echo "[INFO] Run Day14 CI-equivalent suite"
./scripts/day14_ci_suite.sh

echo "[INFO] Verify required Day15 docs"
for f in \
  docs/day15-plan.md \
  docs/day15-release-checklist.md \
  docs/day15-operations-handbook.md \
  docs/day15-v1-backlog.md
do
  if [[ ! -f "$f" ]]; then
    echo "[ERROR] missing required doc: $f"
    exit 1
  fi
done

echo "[INFO] Re-check env checklist"
./scripts/day12_env_check.sh .env.example

echo "[OK] Day15 release readiness checks passed"
