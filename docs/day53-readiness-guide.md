# Day53 Readiness Guide

## Purpose
- 배포 전 마지막 판단을 하나의 리포트로 확인한다.

## Inputs
- `scripts/check_deploy_ready.sh`
- `tmp/reports/day52-ops-manifest-latest.json`
- `tmp/reports/day48-deploy-approval-latest.json`
- `tmp/reports/day51-ops-status-latest.json`

## Decision Rules
- `ready`:
  - deploy check exit code is `0`
  - ops manifest status is `ok`
  - deploy approval decision is `approved`
  - ops status overall is `healthy`
- `blocked`:
  - any condition above is not satisfied

## Outputs
- `tmp/reports/day53-deploy-readiness-<timestamp>.md`
- `tmp/reports/day53-deploy-readiness-<timestamp>.json`
- `tmp/reports/day53-deploy-readiness-latest.md`
- `tmp/reports/day53-deploy-readiness-latest.json`

## Run
```bash
./scripts/day53_deploy_readiness_report.sh tmp/reports tmp/reports
```
