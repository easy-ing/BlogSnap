# Day62 UAT Session Guide

## Purpose
- 직접 테스트할 때 필요한 주소, 순서, 기대 결과, 이슈 기록 양식을 한 번에 제공한다.
- Day61 preview readiness가 `ready`인지 먼저 확인해 잘못된 URL이나 proxy 설정 문제를 테스트 전에 잡는다.

## Inputs
- `tmp/reports/day61-preview-readiness-latest.json`
- frontend URL via `FRONTEND_URL`
- backend API URL via `API_URL`
- current git branch and commit

The script refreshes Day61 preview readiness before creating the UAT packet by default.

## Outputs
- `tmp/reports/day62-uat-session-<timestamp>.md`
- `tmp/reports/day62-uat-session-<timestamp>.json`
- `tmp/reports/day62-uat-session-latest.md`
- `tmp/reports/day62-uat-session-latest.json`

## Manual Flow
- Open web preview
- Login
- Create or select project
- Configure post type, keyword, draft count, sentiment
- Generate drafts
- Regenerate a draft
- Select a draft
- Publish selected draft
- Check backend health/docs only when debugging API status

## Status
- `ready`: UAT can start
- `needs_attention`: required checks passed, optional items need review
- `blocked`: required readiness evidence is missing or failed

## Common URLs
- Web preview: `http://localhost:5173/`
- Backend health: `http://localhost:8000/health`
- Backend OpenAPI docs: `http://localhost:8000/docs`

## Run
```bash
API_URL=http://127.0.0.1:8000 \
FRONTEND_URL=http://127.0.0.1:5173 \
./scripts/day62_uat_session_packet.sh tmp/reports tmp/reports
```
