# Day60 Post-Deploy Smoke Guide

## Purpose
- 배포 직후 사용자가 실제로 마주칠 핵심 API 경로가 살아있는지 빠르게 확인한다.
- Day59 verification이 최신 HEAD와 일치하는지도 함께 확인해 배포 증빙 체인을 유지한다.

## Inputs
- `tmp/reports/day59-post-deploy-verification-latest.json`
- deployed API base URL via `API_URL`
- current git branch and commit

The script refreshes Day59 verification before running smoke checks.

## Outputs
- `tmp/reports/day60-post-deploy-smoke-<timestamp>.md`
- `tmp/reports/day60-post-deploy-smoke-<timestamp>.json`
- `tmp/reports/day60-post-deploy-smoke-latest.md`
- `tmp/reports/day60-post-deploy-smoke-latest.json`

## Checks
- Day59 verification is `ready`
- Day59 branch/commit matches current git state
- `GET /health` returns `status=ok`
- `GET /health/ready` returns `status=ready`
- `POST /v1/auth/login` returns an access token
- `POST /v1/projects` creates a smoke project
- `GET /v1/jobs/queue-summary` returns queue counters
- `GET /health/metrics` returns expected metrics when `METRICS_REQUIRED=yes`
- local worker container is checked as optional unless `WORKER_CHECK_REQUIRED=yes`

## Status
- `ready`: all required and optional checks passed
- `needs_attention`: required checks passed, optional checks failed
- `failed`: one or more required checks failed

## Environment
- `API_URL`: target API URL, default `http://127.0.0.1:8000`
- `SMOKE_TIMEOUT_SECONDS`: per-request timeout, default `5`
- `SMOKE_STRICT`: fail with non-zero exit code when smoke is not `ready`, default `no`
- `METRICS_REQUIRED`: require `/health/metrics`, default `yes`
- `WORKER_CHECK_REQUIRED`: require local docker worker container check, default `no`

## Run
```bash
API_URL=http://127.0.0.1:8000 \
DEPLOY_TARGET=staging \
DEPLOY_ACTION=dry-run \
./scripts/day60_post_deploy_smoke_check.sh tmp/reports tmp/reports
```

## Strict Gate
```bash
SMOKE_STRICT=yes \
API_URL=https://api.example.com \
DEPLOY_TARGET=production \
DEPLOY_ACTION=execute \
CONFIRM_DEPLOY=yes \
./scripts/day60_post_deploy_smoke_check.sh tmp/reports tmp/reports
```
