# Day 18 실행 계획 (2026-04-21)

## 목표
- publish 요청에 예약 시간(`publish_at`)을 추가한다.
- 예약 시간 전에는 발행이 실행되지 않도록 worker 실행 경로를 보호한다.

## 오늘 할 일
1. [x] publish schema에 `publish_at` 필드 추가
2. [x] publish job 생성 시 예약시간 기반 초기 상태(`RETRYING`) 설정
3. [x] 수동 실행 API가 예약시간을 우회하지 못하도록 가드 추가
4. [x] Day18 예약 발행 데모 스크립트 추가
5. [x] 테스트/README/로드맵 업데이트

## 산출물
- [backend/app/schemas/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/publish.py)
- [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
- [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- [scripts/day18_scheduled_publish_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day18_scheduled_publish_demo.sh)
- [tests/test_scheduled_publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_scheduled_publish.py)

## 메모
- MVP 단계에서는 예약정보를 `jobs.next_retry_at`로 운용한다.
- 추후 Day19+에서 예약 큐 고도화(전용 스케줄러/우선순위)로 확장 가능.
