# Day28 Plan - Asset Safety Guardrails

## 목표
- asset 업로드/사용 흐름의 운영 안전성을 강화한다.

## 완료
1. [x] 업로드 허용 타입 검증 (`ASSET_ALLOWED_CONTENT_TYPES`)
2. [x] 업로드 최대 용량 제한 (`ASSET_MAX_BYTES`)
3. [x] asset 삭제 API 추가 (`DELETE /v1/assets/{asset_id}`)
4. [x] 삭제 asset이 목록에서 제외되도록 처리
5. [x] draft 생성 시 `image_asset_id` 상태/소유 검증 강화
6. [x] Day28 테스트 추가

## 변경 파일
- [backend/app/api/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/assets.py)
- [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
- [backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py)
- [tests/test_assets_api.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_assets_api.py)
- [tests/test_draft_asset_validation.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_draft_asset_validation.py)
