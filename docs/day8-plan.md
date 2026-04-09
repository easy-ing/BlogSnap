# Day 8 실행 계획 (2026-04-09)

## 목표
- Day7 로컬 운영 스택에 관측성을 추가한다.
- API/Worker 동작을 메트릭으로 확인할 수 있게 한다.

## 오늘 할 일
1. [x] Prometheus 메트릭 엔드포인트 추가 (`GET /metrics`)
2. [x] 요청 메트릭 수집 추가 (count/latency)
3. [x] Job 처리 메트릭 수집 추가 (processed/retried/failed)
4. [x] Prometheus 로컬 스크래핑 구성 추가
5. [x] Day8 관측 스모크 스크립트 추가/검증
6. [x] README/Backend README 업데이트

## 산출물
- [backend/app/core/metrics.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/metrics.py)
- [backend/app/core/middleware.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/middleware.py)
- [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- [backend/app/api/health.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/health.py)
- [monitoring/prometheus.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/prometheus.yml)
- [scripts/day8_observability_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day8_observability_demo.sh)

## 메모
- Day8 검증은 local docker stack 기준
- 알람 규칙(Alertmanager)은 Day9+ 확장
