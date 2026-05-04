# Day29 Plan - Asset Purge Maintenance

## 목표
- soft-delete 된 asset의 장기 누적을 방지하기 위해 purge 관리 기능을 추가한다.

## 완료
1. [x] `POST /v1/assets/cleanup` 추가 (project 단위 purge)
2. [x] `ASSET_DELETED_RETENTION_HOURS` 설정 추가
3. [x] retention 지난 `DELETED` asset DB/파일 제거
4. [x] Day29 테스트 추가 (`test_cleanup_purges_old_deleted_assets`)

## 변경 파일
- [backend/app/api/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/assets.py)
- [backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py)
- [backend/app/schemas/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/assets.py)
- [tests/test_assets_api.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_assets_api.py)
