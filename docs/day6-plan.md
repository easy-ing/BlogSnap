# Day 6 실행 계획 (2026-04-07)

## 목표
- Day5의 수동 실행 워커를 상시 실행 가능한 데몬 형태로 확장한다.
- 운영자가 큐 상태를 API로 확인하고 배치 실행할 수 있게 한다.

## 오늘 할 일
1. [x] 워커 배치 실행 기능 추가 (`run_batch`)
2. [x] 워커 데몬 추가 (`run_forever`, poll 기반)
3. [x] Job API 확장 (`run-batch`, `queue-summary`)
4. [x] Day6 데모 스크립트 추가/검증
5. [x] README/Backend README 업데이트

## 산출물
- [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- [backend/app/worker/run_forever.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/run_forever.py)
- [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
- [scripts/day6_run_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day6_run_demo.sh)

## 메모
- Day6 검증은 `mock publish mode` 기준
- 실제 운영 시에는 프로세스 매니저(systemd/supervisor) 연계 필요
