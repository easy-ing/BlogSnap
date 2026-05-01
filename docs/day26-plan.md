# Day26 Plan - Frontend E2E Integration

## 목표
- MVP 백엔드 API를 실제 사용자 플로우로 연결하는 프론트엔드(React + Vite)를 추가한다.
- 로그인 -> 프로젝트 선택 -> 초고 생성(2~3개) -> 선택/재생성 -> 자동 발행까지 1개 화면에서 수행한다.

## 완료 체크리스트
1. [x] `frontend` 앱 초기 구성 (Vite + React + TypeScript)
2. [x] API 프록시 설정 (`/api` -> `http://localhost:8025`)
3. [x] 로그인 + 토큰 저장 + 401 시 refresh 재시도
4. [x] 글 유형/키워드/긍부정/이미지 입력 UI
5. [x] 긍부정 선택 시 예시 문구 노출
6. [x] 초고 생성/재생성/선택 UI
7. [x] 자동 발행 UI 및 결과 표시
8. [x] 모바일 대응 스타일 적용
9. [x] Day26 문서/README 반영

## 변경 파일
- [frontend/src/App.tsx](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/src/App.tsx)
- [frontend/src/main.tsx](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/src/main.tsx)
- [frontend/src/styles.css](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/src/styles.css)
- [frontend/vite.config.ts](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/vite.config.ts)
- [frontend/package.json](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/package.json)
- [frontend/README.md](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/README.md)
- [docs/day26-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day26-plan.md)

## 실행
```bash
cd frontend
npm install
npm run dev
```
