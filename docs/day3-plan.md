# Day 3 실행 계획 (2026-04-04)

## 목표
- Day2에서 정의한 아키텍처를 실제 코드 뼈대로 연결한다.
- DB 스키마와 API 경계를 코드에서 검증 가능한 상태로 만든다.

## 오늘 할 일
1. [x] 백엔드 스캐폴드 생성 (FastAPI + 폴더 구조)
2. [x] DB 연결 설정 추가 (SQLAlchemy + PostgreSQL)
3. [x] 핵심 API 골격 구현 (`/health`, `/v1/drafts/*`, `/v1/publish`, `/v1/jobs/{id}`)
4. [x] 로컬 실행 검증 (의존성 설치 + 서버 기동 + health 확인)
5. [x] README에 Day3 실행 절차/산출물 반영

## 산출물
- [backend/app/main.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/main.py)
- [backend/app/models/entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py)
- [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
- [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
- [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
- [backend/README.md](/Users/jin/Desktop/easy_ing/BlogSnap/backend/README.md)

## 메모
- 워커/큐 처리 로직은 Day4+에서 구현
- 현재 API는 Job enqueue 골격까지 제공
