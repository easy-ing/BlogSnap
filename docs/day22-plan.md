# Day 22 실행 계획 (2026-04-26)

## 목표
- 예약 발행 재조정(reconcile) 루프를 분리해 예약 큐 안정성을 높인다.
- 예약 시각 도달 건을 자동으로 실행 가능 상태로 전환하는 API/워커 경로를 제공한다.

## 오늘 할 일
1. [x] 예약 재조정 로직 모듈 추가 (`worker/scheduler.py`)
2. [x] 재조정 API 추가 (`POST /v1/jobs/reconcile-schedules`)
3. [x] 워커 루프에 reconcile 단계 추가 (`run_forever`)
4. [x] Day22 테스트 추가
5. [x] Day22 데모/문서 업데이트

## 산출물
- [backend/app/worker/scheduler.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/scheduler.py)
- [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
- [backend/app/schemas/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/jobs.py)
- [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- [backend/app/worker/run_forever.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/run_forever.py)
- [tests/test_schedule_reconcile.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_schedule_reconcile.py)
- [scripts/day22_schedule_reconcile_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day22_schedule_reconcile_demo.sh)

## 메모
- Day22는 예약 큐 전용 테이블 분리 없이도 운영 가능한 재조정 루프를 우선 제공한다.
- Day23+에서 우선순위 큐/락 전략을 추가하면 멀티 워커 환경 안정성을 더 높일 수 있다.
