# Day55 Release Lock Guide

## Purpose
- 배포 가능한 상태(`ready`)를 재현 가능한 승인 스냅샷으로 남긴다.

## Inputs
- `tmp/reports/day53-deploy-readiness-latest.json`
- Day53 readiness에 포함된 source files
- current git branch and commit

## Outputs
- `tmp/reports/day55-release-lock-<timestamp>.md`
- `tmp/reports/day55-release-lock-<timestamp>.json`
- `tmp/reports/day55-release-lock-latest.md`
- `tmp/reports/day55-release-lock-latest.json`

## Lock Rule
- `lock_status=locked` only when Day53 readiness decision is `ready` and has no block reasons.
- Otherwise, the script exits with failure after writing the attempted lock payload.

## Run
```bash
./scripts/day55_release_lock_snapshot.sh tmp/reports tmp/reports
```
