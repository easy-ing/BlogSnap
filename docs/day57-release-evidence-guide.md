# Day57 Release Evidence Guide

## Purpose
- 배포 승인에 필요한 최신 evidence 파일들을 한 곳에서 확인한다.

## Evidence Inputs
- Day53 deploy readiness
- Day55 release lock
- Day56 release handoff
- Day52 ops manifest
- Day51 ops status
- Day48 deploy approval
- release health latest

## Outputs
- `tmp/reports/day57-release-evidence-<timestamp>.md`
- `tmp/reports/day57-release-evidence-<timestamp>.json`
- `tmp/reports/day57-release-evidence-latest.md`
- `tmp/reports/day57-release-evidence-latest.json`

## Rule
- `evidence_status=ready` only when:
  - required evidence files exist
  - Day56 handoff status is `ready`
  - Day56 handoff commit matches current HEAD
  - Day56 handoff branch matches current branch

## Run
```bash
./scripts/day57_release_evidence_index.sh tmp/reports tmp/reports
```

Run this again after any new commit before final deployment.
