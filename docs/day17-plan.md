# Day 17 실행 계획 (2026-04-19)

## 목표
- API 인증(로그인 + 토큰)과 프로젝트 단위 접근제어를 도입한다.
- 다른 사용자의 프로젝트/초고/잡에 접근하지 못하도록 권한 경계를 명확히 한다.

## 오늘 할 일
1. [x] 인증 코어(JWT 유사 토큰) 및 현재 사용자 의존성 추가
2. [x] auth API 추가 (`/v1/auth/login`, `/v1/auth/me`)
3. [x] project API 추가 (`/v1/projects`)
4. [x] drafts/publish/jobs API에 소유권 검사 적용
5. [x] Day17 auth/rbac 검증 스크립트 추가
6. [x] README/Backend README/.env.example 업데이트

## 산출물
- [backend/app/core/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/auth.py)
- [backend/app/api/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/auth.py)
- [backend/app/api/projects.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/projects.py)
- [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
- [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
- [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
- [scripts/day17_auth_rbac_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day17_auth_rbac_demo.sh)

## 메모
- Day17은 MVP 수준 인증/권한 최소 구현이다.
- production에서는 정식 JWT 라이브러리, refresh token, 키회전 전략으로 확장 필요.
