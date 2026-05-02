# Day27 Plan - Asset Upload Integration

## 목표
- 프론트 이미지 선택을 백엔드 자산(asset) 저장 흐름과 연결한다.

## 완료
1. [x] `assets` 모델/enum 매핑 추가
2. [x] `POST /v1/assets/upload` (multipart) 추가
3. [x] `GET /v1/assets` 목록 API 추가
4. [x] 프론트에서 이미지 업로드 후 `image_asset_id` 전달
5. [x] API 테스트 추가 (`tests/test_assets_api.py`)

## 변경 파일
- [backend/app/api/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/assets.py)
- [backend/app/models/entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py)
- [backend/app/models/enums.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/enums.py)
- [backend/app/schemas/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/assets.py)
- [backend/app/main.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/main.py)
- [frontend/src/App.tsx](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/src/App.tsx)
- [tests/test_assets_api.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_assets_api.py)
