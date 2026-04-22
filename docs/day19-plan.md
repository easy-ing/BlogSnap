# Day 19 실행 계획 (2026-04-22)

## 목표
- 발행 프로바이더를 WordPress 단일에서 Tistory까지 확장한다.
- worker 발행 모드를 provider별 단일 모드 + 통합 `live` 모드로 확장한다.

## 오늘 할 일
1. [x] `provider_type` enum에 `tistory` 추가
2. [x] worker publish executor를 provider 분기 구조로 리팩터링
3. [x] `publish_to_tistory` 구현 및 설정값 추가
4. [x] `.env.example` + env check 스크립트 확장
5. [x] Day19 데모/테스트/README/로드맵 업데이트

## 산출물
- [backend/app/models/enums.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/enums.py)
- [db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql)
- [backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py)
- [backend/app/worker/publishers.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/publishers.py)
- [backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py)
- [scripts/day19_multi_provider_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day19_multi_provider_demo.sh)
- [tests/test_multi_provider_publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_multi_provider_publish.py)

## 메모
- Day19의 `live` 모드는 publish job의 `provider` 값을 기준으로 분기한다.
- 운영환경에서는 `TISTORY_ACCESS_TOKEN`을 시크릿으로 관리해야 한다.
