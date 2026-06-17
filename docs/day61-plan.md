# Day61 Plan - Preview Readiness Check

## Goal
- 사용자가 웹 미리보기를 열 때 백엔드 API root와 프론트 URL을 혼동하지 않도록 자동 점검한다.

## Checklist
- [x] Day60 smoke latest 자동 갱신
- [x] Vite `/api` proxy 설정 확인
- [x] 프론트 `.env.example` proxy 변수 확인
- [x] README의 preview/backend URL 안내 확인
- [x] 백엔드 `/` 404 기대값 및 `/health` 확인
- [x] 프론트 `http://localhost:5173/` 렌더링 확인
- [x] 프론트 `/api/health` proxy 확인
- [x] `npm run build` 확인
- [x] markdown/json/latest preview readiness 리포트 생성

## Run
```bash
API_URL=http://127.0.0.1:8000 \
FRONTEND_URL=http://127.0.0.1:5173 \
./scripts/day61_preview_readiness_check.sh tmp/reports tmp/reports
```

## Strict Mode
```bash
PREVIEW_STRICT=yes \
API_URL=http://127.0.0.1:8000 \
FRONTEND_URL=http://127.0.0.1:5173 \
./scripts/day61_preview_readiness_check.sh tmp/reports tmp/reports
```
