# BlogSnap Frontend (Day26)

React + Vite 기반의 MVP 프론트엔드입니다.

## Run

```bash
cd frontend
npm install
npm run dev
```

기본값으로 `http://localhost:5173`에서 실행되며 `/api` 요청은 `http://localhost:8025`로 프록시됩니다.

## MVP Flow

1. 로그인 (`/v1/auth/login`)
2. 프로젝트 생성/선택 (`/v1/projects`)
3. 초고 생성 (`/v1/drafts/generate` + `/v1/jobs/run-next`)
4. 초고 선택/재생성 (`/v1/drafts/{id}/select`, `/v1/drafts/{id}/regenerate`)
5. 자동 발행 (`/v1/publish` + `/v1/jobs/run-next`)

## Note

- 이미지 업로드는 현재 로컬 미리보기만 지원합니다. (백엔드 asset 업로드 API는 Day27+ 확장)
