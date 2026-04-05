# Day 4 실행 계획 (2026-04-05)

## 목표
- Day3의 "Job enqueue 골격"을 실제 실행 가능한 워커로 연결한다.
- 재시도 정책과 상태 전이(PENDING/RUNNING/RETRYING/SUCCEEDED/FAILED)를 코드로 반영한다.

## 오늘 할 일
1. [x] Job Runner 추가 (다음 실행 가능 Job claim + 실행)
2. [x] Job Executor 추가 (draft_generate / draft_regenerate / publish 처리)
3. [x] Retry 정책 코드 반영 (지수 백오프 + max_attempts)
4. [x] API 수동 실행 엔드포인트 추가 (`POST /v1/jobs/{job_id}/run`, `POST /v1/jobs/run-next`)
5. [x] Day4 데모 시드/실행 검증
6. [x] README 업데이트

## 산출물
- [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- [backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py)
- [backend/app/worker/retry_policy.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/retry_policy.py)
- [backend/app/worker/run_once.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/run_once.py)
- [scripts/day4_seed_demo.py](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day4_seed_demo.py)
- [scripts/day4_run_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day4_run_demo.sh)

## 메모
- publish는 Day4에서 `mock` 모드로 동작
- 실제 WordPress publish worker 연동은 Day5+ 확장
