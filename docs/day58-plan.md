# Day58 Plan - Deployment Execution Receipt

## Goal
- Day57 evidence를 기준으로 배포 실행 직전 receipt를 생성한다.

## Checklist
- [x] Day57 evidence latest 자동 갱신
- [x] evidence commit/branch와 현재 HEAD 비교
- [x] dry-run/execute action 구분
- [x] execute action은 `CONFIRM_DEPLOY=yes` 요구
- [x] markdown/json/latest receipt 생성
- [x] Day58 실행 검증

## Run
```bash
DEPLOY_TARGET=staging DEPLOY_ACTION=dry-run \
  ./scripts/day58_deployment_execution_receipt.sh tmp/reports tmp/reports
```
