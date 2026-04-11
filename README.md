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
- `WORKER_POLL_SECONDS`, `WORKER_BATCH_SIZE`
- `LOG_LEVEL`
- `PROMETHEUS_ENABLED`
- `GRAFANA_ADMIN_PASSWORD`
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

## Day 6 진행 현황 (2026-04-07)
- 실행 계획: [docs/day6-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day6-plan.md)
- 워커 데몬:
  - [backend/app/worker/run_forever.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/run_forever.py)
  - 배치 실행: `run_batch(limit)`
- Job API 확장:
  - `POST /v1/jobs/run-batch?limit=...`
  - `GET /v1/jobs/queue-summary`
- 데모 스크립트:
  - [scripts/day6_seed_many_jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day6_seed_many_jobs.py)
  - [scripts/day6_run_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day6_run_demo.sh)

### Day 6 데모 실행
```bash
docker compose -f docker-compose.dev.yml up -d postgres
./scripts/day6_run_demo.sh
```

위 흐름에서 `queue-summary(before/after)`와 `run-batch`, `daemon(max-loops)` 처리 결과를 확인합니다.

## Day 7 진행 현황 (2026-04-08)
- 실행 계획: [docs/day7-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day7-plan.md)
- 운영형 로컬 스택:
  - [Dockerfile.backend](/Users/jin/Desktop/easy_ing/BlogSnap/Dockerfile.backend)
  - [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml) (`postgres + api + worker`)
- 헬스체크 확장:
  - `GET /health`
  - `GET /health/ready` (DB readiness)
- 요청 로깅:
  - [backend/app/core/middleware.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/middleware.py)
  - request_id, status_code, duration_ms 기록
- 스모크 테스트:
  - [scripts/day7_smoke_test.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day7_smoke_test.sh)
  - [scripts/day7_run_stack.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day7_run_stack.sh)

### Day 7 실행
```bash
./scripts/day7_run_stack.sh
```

위 실행으로 `health`, `health/ready`, `queue-summary`까지 자동 확인합니다.

## Day 8 진행 현황 (2026-04-09)
- 실행 계획: [docs/day8-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day8-plan.md)
- 메트릭 추가:
  - [backend/app/core/metrics.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/metrics.py)
  - `GET /health/metrics` (Prometheus 형식)
- 요청/잡 메트릭 수집:
  - HTTP requests total / duration
  - jobs processed outcome(succeeded/retrying/failed)
- Prometheus 연동:
  - [monitoring/prometheus.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/prometheus.yml)
  - [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml) (`prometheus` 서비스 추가)
- 관측 데모:
  - [scripts/day8_observability_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day8_observability_demo.sh)

### Day 8 실행
```bash
./scripts/day8_observability_demo.sh
```

위 실행으로 API metrics 샘플과 Prometheus target `health=up` 상태를 확인합니다.

## Day 9 진행 현황 (2026-04-10)
- 실행 계획: [docs/day9-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day9-plan.md)
- Alert rules:
  - [monitoring/rules/blogsnap-alerts.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/rules/blogsnap-alerts.yml)
- Alertmanager:
  - [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml)
- Grafana provisioning:
  - [monitoring/grafana/provisioning/datasources/prometheus.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/grafana/provisioning/datasources/prometheus.yml)
  - [monitoring/grafana/provisioning/dashboards/dashboards.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/grafana/provisioning/dashboards/dashboards.yml)
  - [monitoring/grafana/dashboards/blogsnap-overview.json](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/grafana/dashboards/blogsnap-overview.json)
- Day9 데모:
  - [scripts/day9_observability_plus_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day9_observability_plus_demo.sh)

### Day 9 실행
```bash
./scripts/day9_observability_plus_demo.sh
```

위 실행으로 Prometheus rules 로드, Alertmanager ready, Grafana datasource(provisioned)까지 확인합니다.

## Day 10 진행 현황 (2026-04-11)
- 실행 계획: [docs/day10-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day10-plan.md)
- 알림 전달 webhook 수신기:
  - [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py)
- Alertmanager webhook 연결 업데이트:
  - [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml)
- compose 서비스 확장:
  - [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml) (`alert-webhook` 추가)
- 운영 대응 문서:
  - [docs/day10-alert-runbook.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day10-alert-runbook.md)
- Day10 데모:
  - [scripts/day10_alert_delivery_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day10_alert_delivery_demo.sh)

### Day 10 실행
```bash
./scripts/day10_alert_delivery_demo.sh
```

위 실행으로 synthetic alert 전송 후 webhook 수신 로그 기록까지 검증합니다.
