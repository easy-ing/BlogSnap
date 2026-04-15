# Day 14 실행 계획 (2026-04-15)

## 목표
- PR 기준 자동 검증 파이프라인(CI)을 구성한다.
- 로컬에서도 CI와 동일한 명령으로 재현 가능하게 한다.

## 오늘 할 일
1. [x] GitHub Actions CI workflow 추가
2. [x] CI 실행 스크립트 추가 (lint/test/compile/check)
3. [x] 테스트 픽스처 CI 호환 보강
4. [x] CI 실패 디버깅 가이드 문서화
5. [x] README/Backend README/로드맵 업데이트

## 산출물
- [.github/workflows/ci.yml](/Users/jin/Desktop/easy_ing/BlogSnap/.github/workflows/ci.yml)
- [scripts/day14_ci_suite.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day14_ci_suite.sh)
- [tests/conftest.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/conftest.py)
- [docs/day14-ci-debug-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day14-ci-debug-guide.md)

## 메모
- CI DB는 GitHub Actions `postgres` service를 사용한다.
- 테스트는 `TEST_DB_RESET_MODE=skip`로 설정해 CI에서 docker 의존을 제거한다.
