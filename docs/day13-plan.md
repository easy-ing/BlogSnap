# Day 13 실행 계획 (2026-04-14)

## 목표
- API/Worker 테스트를 추가해 핵심 플로우 회귀를 빠르게 감지한다.
- 로컬에서 재현 가능한 테스트 실행 스크립트를 제공한다.

## 오늘 할 일
1. [x] 테스트 기반(폴더/픽스처) 구성 추가
2. [x] 핵심 플로우 통합 테스트 추가 (draft 생성→선택→publish)
3. [x] 워커 재시도 로직 단위 테스트 추가
4. [x] Day13 테스트 실행 스크립트 추가
5. [x] Day13 문서/README 업데이트

## 산출물
- [tests/conftest.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/conftest.py)
- [tests/test_api_flow.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_api_flow.py)
- [tests/test_job_runner_retry.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_job_runner_retry.py)
- [scripts/day13_test_suite.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day13_test_suite.sh)
- [docs/day13-test-strategy.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day13-test-strategy.md)

## 메모
- 테스트는 로컬 Postgres + 기존 migration 기준으로 동작한다.
- Day14 CI에서 동일 명령을 PR 자동 검증 단계로 연결할 예정이다.
