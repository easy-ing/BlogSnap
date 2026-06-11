# Day58 Deployment Receipt Guide

## Purpose
- 배포 실행 직전의 승인 맥락을 receipt로 남긴다.

## Inputs
- `tmp/reports/day57-release-evidence-latest.json`
- current git branch and commit

The script refreshes Day57 evidence before creating the receipt.

## Outputs
- `tmp/reports/day58-deployment-receipt-<timestamp>.md`
- `tmp/reports/day58-deployment-receipt-<timestamp>.json`
- `tmp/reports/day58-deployment-receipt-latest.md`
- `tmp/reports/day58-deployment-receipt-latest.json`

## Modes
- `DEPLOY_ACTION=dry-run`: approval context only
- `DEPLOY_ACTION=execute`: requires `CONFIRM_DEPLOY=yes`

## Important
- This script does not perform production deployment.
- It records whether the current commit is backed by ready Day57 evidence.

## Run
```bash
DEPLOY_TARGET=staging DEPLOY_ACTION=dry-run \
  ./scripts/day58_deployment_execution_receipt.sh tmp/reports tmp/reports
```
