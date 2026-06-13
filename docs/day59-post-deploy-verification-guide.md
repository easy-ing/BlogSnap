# Day59 Post-Deploy Verification Guide

## Purpose
- 배포 실행 전후로 Day58 receipt가 최신 HEAD와 승인 evidence를 정확히 가리키는지 확인한다.

## Inputs
- `tmp/reports/day58-deployment-receipt-latest.json`
- `tmp/reports/day57-release-evidence-latest.json`
- current git branch and commit

The script refreshes Day58 receipt before creating the verification report.

## Outputs
- `tmp/reports/day59-post-deploy-verification-<timestamp>.md`
- `tmp/reports/day59-post-deploy-verification-<timestamp>.json`
- `tmp/reports/day59-post-deploy-verification-latest.md`
- `tmp/reports/day59-post-deploy-verification-latest.json`

## Checks
- `receipt_status` is `ready`
- receipt `execution_state` matches `DEPLOY_ACTION`
- receipt branch/commit matches current git state
- receipt target/action matches requested deploy context
- evidence branch/commit matches current git state

## Modes
- `DEPLOY_ACTION=dry-run`: rehearsal verification
- `DEPLOY_ACTION=execute`: requires Day58 execute confirmation through `CONFIRM_DEPLOY=yes`

## Important
- This script does not deploy the application.
- It records whether the latest deployment receipt is safe to use as an execution proof.

## Run
```bash
DEPLOY_TARGET=staging DEPLOY_ACTION=dry-run \
  ./scripts/day59_post_deploy_verification.sh tmp/reports tmp/reports
```
