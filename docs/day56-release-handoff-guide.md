# Day56 Release Handoff Guide

## Purpose
- 배포 승인 시점에 release lock과 현재 git 상태가 일치하는지 검증한다.

## Inputs
- Day53 deploy readiness latest
- Day55 release lock latest
- Current git branch and commit

## Outputs
- `tmp/reports/day56-release-handoff-<timestamp>.md`
- `tmp/reports/day56-release-handoff-<timestamp>.json`
- `tmp/reports/day56-release-handoff-latest.md`
- `tmp/reports/day56-release-handoff-latest.json`

## Verification
- release lock status is `locked`
- lock commit matches current HEAD
- lock branch matches current branch
- readiness checksum still matches
- every source checksum still matches

## Run
```bash
./scripts/day56_release_handoff_package.sh tmp/reports tmp/reports
```
