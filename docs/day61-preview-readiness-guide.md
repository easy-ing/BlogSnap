# Day61 Preview Readiness Guide

## Purpose
- 웹 미리보기에서 `Not Found`가 보일 때 원인이 서버 장애인지, 잘못된 URL 접근인지 빠르게 구분한다.
- BlogSnap의 실제 프론트 화면은 Vite dev server인 `http://localhost:5173/`에서 열린다.
- 백엔드 API는 `http://localhost:8000`이며 root `/`는 404가 날 수 있다.

## Inputs
- `tmp/reports/day60-post-deploy-smoke-latest.json`
- frontend Vite URL via `FRONTEND_URL`
- backend API URL via `API_URL`
- current git branch and commit

The script refreshes Day60 smoke checks before preview checks by default.

## Outputs
- `tmp/reports/day61-preview-readiness-<timestamp>.md`
- `tmp/reports/day61-preview-readiness-<timestamp>.json`
- `tmp/reports/day61-preview-readiness-latest.md`
- `tmp/reports/day61-preview-readiness-latest.json`

## Checks
- Day60 smoke status is `ready`
- Vite proxy defaults `/api` to `http://localhost:8000`
- frontend `.env.example` documents `VITE_API_BASE` and `VITE_API_PROXY_TARGET`
- README docs include the correct preview/backend URLs
- backend root behavior matches `EXPECT_API_ROOT_404`
- backend `/health` returns `status=ok`
- frontend root renders the React app shell
- frontend `/api/health` reaches backend health through proxy
- frontend production build succeeds

## Status
- `ready`: all required preview checks passed
- `needs_attention`: required checks passed, optional checks failed
- `failed`: one or more required checks failed

## Common URLs
- Web preview: `http://localhost:5173/`
- Backend health: `http://localhost:8000/health`
- Backend OpenAPI docs: `http://localhost:8000/docs`
- Backend root: `http://localhost:8000/` may return `Not Found`

## Environment
- `API_URL`: backend API URL, default `http://127.0.0.1:8000`
- `FRONTEND_URL`: frontend preview URL, default `http://127.0.0.1:5173`
- `PREVIEW_TIMEOUT_SECONDS`: request timeout, default `5`
- `PREVIEW_STRICT`: fail with non-zero exit code when preview is not `ready`, default `no`
- `RUN_FRONTEND_BUILD`: run `npm run build`, default `yes`
- `REFRESH_DAY60`: run Day60 before preview checks, default `yes`
- `EXPECT_API_ROOT_404`: treat backend root 404 as expected, default `yes`

## Run
```bash
API_URL=http://127.0.0.1:8000 \
FRONTEND_URL=http://127.0.0.1:5173 \
./scripts/day61_preview_readiness_check.sh tmp/reports tmp/reports
```
