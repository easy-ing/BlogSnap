# BlogSnap

BlogSnap은 `키워드 + 사진 + 감정 강도`를 기반으로 블로그 초고를 2~3개 생성하고, 사용자가 선택한 초고를 자동 업로드하는 프로젝트입니다.

## Day 1 완료 기록 (2026-04-02)
오늘은 **요구사항 정의(PRD v1) + 동작하는 MVP 구현**까지 완료했습니다.

### Day 1 문제 정의
- 블로그 작성/업로드가 반복적이고 번거롭다.
- 최소 입력으로 글 생성부터 게시까지 자동화가 필요하다.

### Day 1 핵심 사용자 플로우
1. 글 종류 선택 (`리뷰 / 설명형 / 소감문`)
2. 키워드 입력
3. 사진 업로드
4. 긍정/부정 강도 선택 (`-2 ~ +2`) + 예시 가이드 확인
5. 초고 2~3개 생성
6. 마음에 드는 초고 선택
7. 선택 초고 자동 업로드

### Day 1 범위 확정
`In Scope`
- 글 종류 선택
- 감정 강도 기반 톤 제어
- 초고 2~3개 생성
- 초고 재생성
- 선택 초고 자동 업로드(WordPress)

`Out of Scope`
- 멀티 사용자 인증/권한
- 백엔드 서버 분리(FastAPI)
- DB 영속 저장
- 예약 발행/큐/재시도
- 티스토리/네이버 연동

### Day 1 완료 기준(DoD)
- 요구사항 문서화 완료
- 필수/제외 기능 분리 완료
- MVP 성공 시나리오 정의 완료
- Day 2 착수 조건 명확화 완료

## 현재 MVP 구현 상태
- Streamlit UI 플로우 구현
- OpenAI 기반 초고 2~3개 생성
- 다른 방향성으로 재생성 가능
- 선택 초고 WordPress 자동 업로드
- 이미지 미디어 업로드 + 대표 이미지 설정

## 실행 방법
### 1) 설치
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2) 환경 변수
```bash
cp .env.example .env
```

`.env` 항목:
- `OPENAI_API_KEY`
- `OPENAI_MODEL` (예: `gpt-5-mini`)
- `DATABASE_URL` (예: `postgresql+psycopg://blogsnap:blogsnap@localhost:55432/blogsnap`)
- `WORKER_PUBLISH_MODE` (`mock` 또는 `wordpress`)
- `WORDPRESS_BASE_URL`, `WORDPRESS_USERNAME`, `WORDPRESS_APP_PASSWORD` (wordpress 모드 시)
- `BLOG_PROVIDER=wordpress`
- `BLOG_BASE_URL`
- `BLOG_USERNAME`
- `BLOG_APP_PASSWORD`
- `DEFAULT_TAGS`

### 3) 앱 실행
```bash
streamlit run app.py
```

### 4) 로컬 DB 마이그레이션 검증
```bash
docker compose -f docker-compose.dev.yml up -d postgres
./scripts/db_apply_migration.sh
./scripts/db_verify_schema.sh
```

필요 시 컨테이너 종료:
```bash
docker compose -f docker-compose.dev.yml down
```

## 브랜치 운영 전략
- `main`: 항상 배포 가능한 안정 브랜치
- `develop`: 통합 작업 브랜치
- 기능 브랜치: `codex/feat/...`, `codex/chore/...`, `codex/fix/...`

추천 규칙:
1. PR 하나 = 목적 하나
2. PR은 작게 유지(가능하면 300줄 내외)
3. 머지 대상은 기본적으로 `develop`
4. `main`은 릴리즈/핫픽스만 머지

## PR 템플릿
- 기본 템플릿: [.github/pull_request_template.md](/Users/jin/Desktop/easy_ing/BlogSnap/.github/pull_request_template.md)

## 주요 파일
- [app.py](/Users/jin/Desktop/easy_ing/BlogSnap/app.py): UI 기반 생성/선택/업로드
- [main.py](/Users/jin/Desktop/easy_ing/BlogSnap/main.py): CLI 진입점
- [blogsnap/ai_writer.py](/Users/jin/Desktop/easy_ing/BlogSnap/blogsnap/ai_writer.py): 초고 생성 로직
- [blogsnap/blog_clients/wordpress.py](/Users/jin/Desktop/easy_ing/BlogSnap/blogsnap/blog_clients/wordpress.py): WordPress 업로드
- [blogsnap/pipeline.py](/Users/jin/Desktop/easy_ing/BlogSnap/blogsnap/pipeline.py): CLI 파이프라인

## 다음 챕터
- **Day 2: 시스템 아키텍처 설계**
- 목표: 프론트/백엔드/비동기 작업/DB 경계 정의
- 문서 초안: [docs/day2-architecture.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day2-architecture.md)
- Day3 준비 산출물:
  - [docs/day3-db-schema.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day3-db-schema.md)
  - [db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql)
  - [docs/day3-retry-policy.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day3-retry-policy.md)

## Day 3 진행 현황 (2026-04-04)
- 실행 계획: [docs/day3-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day3-plan.md)
- 백엔드 스캐폴드: [backend/app/main.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/main.py)
- DB 모델: [backend/app/models/entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py)
- API 골격:
  - [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
  - [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
  - [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)

### Day 3 로컬 실행
```bash
python3 -m pip install -r requirements.txt
docker compose -f docker-compose.dev.yml up -d postgres
./scripts/db_apply_migration.sh
python3 -m uvicorn backend.app.main:app --reload --port 8000
```

헬스체크:
```bash
curl http://127.0.0.1:8000/health
```

## Day 4 진행 현황 (2026-04-05)
- 실행 계획: [docs/day4-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day4-plan.md)
- 워커 런너: [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- 워커 실행기: [backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py)
- 재시도 정책: [backend/app/worker/retry_policy.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/retry_policy.py)
- 수동 실행 API:
  - `POST /v1/jobs/{job_id}/run`
  - `POST /v1/jobs/run-next`
- 데모 스크립트:
  - [scripts/day4_seed_demo.py](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day4_seed_demo.py)
  - [scripts/day4_run_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day4_run_demo.sh)

### Day 4 데모 실행
```bash
docker compose -f docker-compose.dev.yml up -d postgres
./scripts/db_reset.sh
./scripts/day4_run_demo.sh
```

위 흐름에서 `draft_generate` Job이 `SUCCEEDED`로 전이되고, Draft 3건 생성되는 것을 확인합니다.

## Day 5 진행 현황 (2026-04-06)
- 실행 계획: [docs/day5-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day5-plan.md)
- 추가 API:
  - `POST /v1/drafts/{draft_id}/select`
  - `GET /v1/publish/{publish_job_id}`
- publish worker 확장:
  - `mock` 모드
  - `wordpress` 모드 (환경변수 기반)
- 발행 idempotency 처리:
  - 동일 `idempotency_key` 발행 요청 시 기존 Job 재사용

### Day 5 데모 실행
```bash
docker compose -f docker-compose.dev.yml up -d postgres
./scripts/db_reset.sh
./scripts/day5_run_demo.sh
```

위 흐름에서 `draft 선택 -> publish job 생성 -> job 실행 -> publish 조회(PUBLISHED)`까지 확인합니다.
