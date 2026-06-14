# Day60 Plan - Post-Deploy Smoke Check

## Goal
- Day59 verification 이후 실제 배포 대상 API가 최소 동작 상태인지 확인한다.

## Checklist
- [x] Day59 verification latest 자동 갱신
- [x] `/health` 상태 확인
- [x] `/health/ready` DB readiness 확인
- [x] 로그인 및 프로젝트 생성 smoke 확인
- [x] queue summary smoke 확인
- [x] metrics endpoint 확인
- [x] worker 컨테이너 상태 optional 확인
- [x] markdown/json/latest smoke 리포트 생성

## Run
```bash
API_URL=http://127.0.0.1:8000 \
DEPLOY_TARGET=staging \
DEPLOY_ACTION=dry-run \
./scripts/day60_post_deploy_smoke_check.sh tmp/reports tmp/reports
```

## Strict Mode
```bash
SMOKE_STRICT=yes \
API_URL=http://127.0.0.1:8000 \
./scripts/day60_post_deploy_smoke_check.sh tmp/reports tmp/reports
```
