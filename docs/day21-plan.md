# Day 21 실행 계획 (2026-04-24)

## 목표
- 예약 발행 제어 기능(예약 수정/취소)을 API로 제공한다.
- 취소된 예약은 워커 실행 경로에서 확실히 차단한다.

## 오늘 할 일
1. [x] `publish_jobs` 예약 상태 필드 확장(`schedule_status`, `scheduled_at`, `cancelled_at`)
2. [x] 예약 수정 API 추가 (`PATCH /v1/publish/{publish_job_id}/schedule`)
3. [x] 예약 취소 API 추가 (`POST /v1/publish/{publish_job_id}/cancel`)
4. [x] 워커 취소 예약 실행 차단 가드 추가
5. [x] Day21 테스트/데모/문서 업데이트

## 산출물
- [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
- [backend/app/schemas/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/publish.py)
- [backend/app/models/enums.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/enums.py)
- [backend/app/models/entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py)
- [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- [db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql)
- [tests/test_scheduled_publish_controls.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_scheduled_publish_controls.py)
- [scripts/day21_scheduling_control_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day21_scheduling_control_demo.sh)

## 메모
- Day21에서는 예약 큐 전용 테이블 분리는 하지 않고, 기존 job/publish_job 구조를 확장해 제어 API를 우선 제공했다.
- Day22+에서 전용 스케줄러 루프(예약 스캔/재조정)를 분리하면 운영 안정성을 더 높일 수 있다.
