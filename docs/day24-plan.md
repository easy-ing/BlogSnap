# Day 24 실행 계획 (2026-04-29)

## 목표
- Pydantic V2 권장 방식(`ConfigDict`)으로 스키마 설정을 정리한다.
- 테스트 로그의 deprecation warning 노이즈를 줄여 CI 가독성을 개선한다.

## 오늘 할 일
1. [x] schema `class Config` -> `model_config = ConfigDict(...)` 전환
2. [x] from_attributes 설정 유지 검증
3. [x] Day24 문서/로드맵 업데이트
4. [x] 테스트 실행으로 경고 감소 확인

## 산출물
- [backend/app/schemas/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/auth.py)
- [backend/app/schemas/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/drafts.py)
- [backend/app/schemas/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/jobs.py)
- [backend/app/schemas/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/publish.py)
- [backend/app/schemas/projects.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/projects.py)

## 메모
- Day24는 동작 변경 없이 스키마 선언 스타일을 최신화하는 유지보수성 개선 작업이다.
