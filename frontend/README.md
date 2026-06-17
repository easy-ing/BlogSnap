# BlogSnap Frontend (Day27)

## Run

```bash
cd frontend
npm install
npm run dev
```

브라우저 미리보기는 아래 주소를 엽니다.

```text
http://localhost:5173/
```

기본 `/api` 프록시는 `http://localhost:8000` 백엔드를 가리킵니다.

백엔드가 다른 포트에서 실행 중이면 아래처럼 지정할 수 있습니다.

```bash
VITE_API_PROXY_TARGET=http://localhost:8000 npm run dev
```

## Day27

- 이미지 파일 업로드 API 연동 (`POST /v1/assets/upload`)
- 업로드된 `image_asset_id`를 초고 생성 요청에 연결
