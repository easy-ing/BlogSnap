# Day 7 실행 계획 (2026-04-08)

## 목표
- 로컬 개발 환경을 운영에 가까운 실행 형태(API + Worker + DB)로 구성한다.
- 서비스 상태를 빠르게 확인할 수 있도록 readiness와 스모크 테스트를 추가한다.
- 요청 단위 추적을 위해 기본 구조화 로그를 추가한다.

## 오늘 할 일
1. [x] API/Worker 컨테이너 실행 구성 추가 (Dockerfile + compose)
2. [x] readiness 체크 엔드포인트 추가 (`GET /health/ready`)
3. [x] 요청 로깅 미들웨어 추가 (request_id, status_code, duration)
4. [x] Day7 스모크 테스트 스크립트 추가/검증
5. [x] README/Backend README 업데이트

## 산출물
- [Dockerfile.backend](/Users/jin/Desktop/easy_ing/BlogSnap/Dockerfile.backend)
- [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml)
- [backend/app/api/health.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/health.py)
- [backend/app/core/logging.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/logging.py)
- [backend/app/core/middleware.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/middleware.py)
- [scripts/day7_smoke_test.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day7_smoke_test.sh)
- [scripts/day7_run_stack.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day7_run_stack.sh)

## 메모
- Day7는 개발용 운영성 강화 단계
- 프로덕션 배포(PaaS/K8s, secret manager, TLS)는 Day8+에서 확장
