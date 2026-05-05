# Day30 Plan - Asset Cleanup Automation

## 목표
- Day29의 project 단위 cleanup API를 운영 자동화 가능한 실행 경로로 확장한다.

## 완료
1. [x] 공통 purge 서비스 함수 분리 (`purge_deleted_assets_for_project`, `purge_deleted_assets_all_projects`)
2. [x] API가 공통 서비스 함수를 사용하도록 정리
3. [x] 전체 프로젝트 일괄 정리 스크립트 추가 (`scripts/day30_asset_cleanup_run.sh`)
4. [x] 서비스 레벨 테스트 추가 (`tests/test_asset_cleanup_service.py`)

## 변경 파일
- [backend/app/services/asset_cleanup.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/services/asset_cleanup.py)
- [backend/app/api/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/assets.py)
- [scripts/day30_asset_cleanup_run.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day30_asset_cleanup_run.sh)
- [tests/test_asset_cleanup_service.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_asset_cleanup_service.py)
