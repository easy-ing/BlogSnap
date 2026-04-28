# Day 23 실행 계획 (2026-04-28)

## 목표
- 멀티 워커 환경에서 job 중복 클레임 위험을 줄인다.
- project 스코프 실행 경로를 runner 내부로 일원화해 일관성을 높인다.

## 오늘 할 일
1. [x] `claim_next_job`를 DB 락 기반(`FOR UPDATE SKIP LOCKED`)으로 개선
2. [x] `run_next` / `run_batch`에 `project_id` 스코프 지원
3. [x] jobs API에서 수동 질의 루프 제거 후 runner 호출로 통일
4. [x] Day23 프로젝트 스코프 테스트 추가
5. [x] Day23 문서 업데이트

## 산출물
- [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
- [tests/test_job_runner_project_scope.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_job_runner_project_scope.py)

## 메모
- Day23은 DB 락으로 중복 클레임 가능성을 낮추는 1차 안전장치다.
- 완전한 멀티 인스턴스 보장은 Day24+에서 분산 락/큐 아키텍처로 확장한다.
