# Day 3 준비: DB 스키마/Enum/인덱스 확정

## 1) 확정 범위
- 테이블: `users`, `projects`, `assets`, `jobs`, `drafts`, `publish_jobs`, `publish_logs`, `provider_tokens`
- Enum: `post_type`, `job_type`, `job_status`, `draft_status`, `publish_status`, `provider_type`, `asset_status`
- 인덱스: 조회 경로/큐 소비/로그 조회 기반으로 확정

구현 SQL:
- [db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql)

## 2) 설계 요약
### users/projects
- 사용자 1:N 프로젝트
- 프로젝트 단위로 초고/업로드/작업 상태를 분리 관리

### jobs (통합 작업 테이블)
- 생성/재생성/업로드를 하나의 작업 상태머신으로 관리
- `idempotency_key` + `(project_id, type)` 유니크로 중복 실행 방지
- 재시도 관리를 위해 `attempt_count`, `max_attempts`, `next_retry_at` 포함

### drafts
- `version_no`, `variant_no(1~3)`로 초고 세트 관리
- 감정 강도는 `-2 ~ +2` 제약

### publish_jobs/publish_logs
- 게시 작업 이력과 상세 로그를 분리 저장
- 장애 분석 시 로그 추적성 확보

### assets/provider_tokens
- 파일 업로드 메타데이터/외부 연동 토큰 관리

## 3) 인덱스 전략
핵심 쿼리별 인덱스:
- 대시보드 최신순 조회: `(project_id, status, created_at DESC)`
- 큐 워커 pick-up: `(status, next_retry_at)` partial index
- 작업 이력/로그 추적: `publish_job_id + created_at DESC`
- 키워드 검색 확장 대비: `drafts.keyword` tsvector GIN

## 4) 보완 포인트(후속)
- `updated_at` 자동 갱신 trigger 추가
- RLS(Row Level Security) 적용 (Day 5)
- provider_type 확장 (`tistory`, `naver`) 시 enum migration
