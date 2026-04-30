# Day 25 실행 계획 (2026-04-30)

## 목표
- 인증 흐름에 refresh token과 logout(revoke) 기능을 추가한다.
- access token 만료 대응과 세션 무효화를 API 레벨에서 지원한다.

## 오늘 할 일
1. [x] refresh token 세션 저장 테이블 추가
2. [x] 로그인 시 access/refresh 동시 발급
3. [x] `POST /v1/auth/refresh` 토큰 재발급(회전) 추가
4. [x] `POST /v1/auth/logout` refresh 세션 revoke 추가
5. [x] Day25 테스트/데모/문서 업데이트

## 산출물
- [backend/app/core/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/auth.py)
- [backend/app/api/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/auth.py)
- [backend/app/schemas/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/auth.py)
- [backend/app/models/entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py)
- [db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql)
- [tests/test_auth_refresh_logout.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_auth_refresh_logout.py)
- [scripts/day25_auth_refresh_logout_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day25_auth_refresh_logout_demo.sh)

## 메모
- Day25는 refresh token 회전(rotate)을 기본으로 적용했다.
- 후속 Day에서 refresh 세션 기기별 메타데이터(UA/IP) 추적을 추가할 수 있다.
