# Day 5 실행 계획 (2026-04-06)

## 목표
- Day4 워커를 실제 발행 플로우에 가깝게 확장한다.
- 초고 선택/발행 조회/중복 발행 방지(idempotency)까지 API 흐름을 완성한다.

## 오늘 할 일
1. [x] publish worker 모드 확장 (`mock` + `wordpress`)
2. [x] 초고 선택 API 추가 (`POST /v1/drafts/{draft_id}/select`)
3. [x] 발행 조회 API 추가 (`GET /v1/publish/{publish_job_id}`)
4. [x] 발행 요청 idempotency 처리 추가
5. [x] Day5 end-to-end 데모 스크립트 실행 검증
6. [x] README/Backend README 업데이트

## 산출물
- [backend/app/worker/publishers.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/publishers.py)
- [backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py)
- [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
- [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
- [scripts/day5_run_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day5_run_demo.sh)

## 메모
- Day5 기본 검증은 `WORKER_PUBLISH_MODE=mock`
- 실제 WordPress 업로드 검증은 운영 크리덴셜 설정 후 선택 수행
