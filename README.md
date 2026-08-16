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
- `WORKER_DRAFT_MODE` (`mock` / `gemini`) — 초고 생성 방식. `gemini`로 설정하면 아래 `GEMINI_API_KEY`로 실제 AI 초고를 생성합니다.
- `GEMINI_API_KEY`, `GEMINI_MODEL` (예: `gemini-2.5-flash`, [Google AI Studio](https://aistudio.google.com/apikey)에서 무료로 발급)
- `WORKER_PUBLISH_MODE` (`mock` / `wordpress` / `tistory` / `live`)
- `WORKER_POLL_SECONDS`, `WORKER_BATCH_SIZE`
- `LOG_LEVEL`
- `PROMETHEUS_ENABLED`
- `AUTH_SECRET_KEY`, `AUTH_TOKEN_EXP_MINUTES`, `AUTH_REFRESH_TOKEN_EXP_MINUTES`
- `GRAFANA_ADMIN_PASSWORD`
- `WORDPRESS_BASE_URL`, `WORDPRESS_USERNAME`, `WORDPRESS_APP_PASSWORD` (wordpress/live 모드 시)
- `TISTORY_API_URL`, `TISTORY_ACCESS_TOKEN`, `TISTORY_BLOG_NAME` (tistory/live 모드 시)
- `BLOG_PROVIDER=wordpress`
- `BLOG_BASE_URL`
- `BLOG_USERNAME`
- `BLOG_APP_PASSWORD`
- `DEFAULT_TAGS`

### 2.5) 배포 준비 점검
```bash
chmod +x ./scripts/check_deploy_ready.sh
./scripts/check_deploy_ready.sh
```

### 3) 앱 실행
```bash
streamlit run app.py
```

### 3.1) React 프론트 미리보기
백엔드 API는 `http://localhost:8000`, 실제 웹 화면은 `http://localhost:5173`에서 확인합니다.

```bash
docker compose -f docker-compose.dev.yml up -d postgres api worker
cd frontend
npm install
npm run dev
```

브라우저에서는 아래 주소를 엽니다.

```text
http://localhost:5173/
```

참고로 `http://localhost:8000/`은 백엔드 API root라서 `Not Found`가 보일 수 있습니다. API 상태 확인은 `http://localhost:8000/health`, API 문서는 `http://localhost:8000/docs`를 사용합니다.

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

## Day 11 진행 현황 (2026-04-12)
- 실행 계획: [docs/day11-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day11-plan.md)
- 웹훅 relay 확장:
  - [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py) (`ALERT_FORWARD_WEBHOOK_URL` 지원)
- mock sink (로컬 연동 검증):
  - [monitoring/mock_sink/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/mock_sink/server.py)
- compose 서비스 확장:
  - [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml) (`webhook-sink` 추가)
- Day11 데모:
  - [scripts/day11_webhook_relay_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day11_webhook_relay_demo.sh)

### Day 11 실행
```bash
./scripts/day11_webhook_relay_demo.sh
```

위 실행으로 Alertmanager synthetic alert가 alert-webhook을 거쳐 sink로 포워딩되는 것을 검증합니다.

## Day11+ 남은 작업표
- 상세 로드맵: [docs/day11-roadmap.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day11-roadmap.md)

## Day 12 진행 현황 (2026-04-13)
- 실행 계획: [docs/day12-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day12-plan.md)
- Alert routing 분리:
  - [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml) (`warning`/`critical` receiver 분기)
- webhook 채널별 포워딩:
  - [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py)
  - `ALERT_FORWARD_WEBHOOK_URL_WARNING`, `ALERT_FORWARD_WEBHOOK_URL_CRITICAL` 지원
- 로컬 분리 검증 sink:
  - [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml) (`webhook-sink-warning`, `webhook-sink-critical`)
- Day12 데모/점검:
  - [scripts/day12_alert_routing_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day12_alert_routing_demo.sh)
  - [scripts/day12_env_check.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day12_env_check.sh)
- 시크릿 운영 체크리스트:
  - [docs/day12-secrets-checklist.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day12-secrets-checklist.md)

### Day 12 실행
```bash
./scripts/day12_alert_routing_demo.sh
./scripts/day12_env_check.sh
```

위 실행으로 warning/critical 라우팅 분리 전달과 `.env` 민감정보 점검을 확인합니다.

## Day 13 진행 현황 (2026-04-14)
- 실행 계획: [docs/day13-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day13-plan.md)
- 테스트 픽스처/케이스:
  - [tests/conftest.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/conftest.py)
  - [tests/test_api_flow.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_api_flow.py)
  - [tests/test_job_runner_retry.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_job_runner_retry.py)
- 테스트 전략 문서:
  - [docs/day13-test-strategy.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day13-test-strategy.md)
- Day13 실행 스크립트:
  - [scripts/day13_test_suite.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day13_test_suite.sh)

### Day 13 실행
```bash
./scripts/day13_test_suite.sh
```

위 실행으로 DB reset + pytest 통합/단위 테스트를 한 번에 검증합니다.

## Day 14 진행 현황 (2026-04-15)
- 실행 계획: [docs/day14-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day14-plan.md)
- GitHub Actions CI:
  - [.github/workflows/ci.yml](/Users/jin/Desktop/easy_ing/BlogSnap/.github/workflows/ci.yml)
- CI 재현 스크립트:
  - [scripts/day14_ci_suite.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day14_ci_suite.sh)
- CI 디버깅 가이드:
  - [docs/day14-ci-debug-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day14-ci-debug-guide.md)
- 테스트 픽스처 CI 호환:
  - [tests/conftest.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/conftest.py) (`TEST_DB_RESET_MODE=skip`)

### Day 14 실행
```bash
docker compose -f docker-compose.dev.yml up -d postgres
./scripts/day14_ci_suite.sh
```

위 실행으로 lint/test/compile/check를 CI와 동일한 순서로 검증합니다.

## Day 15 진행 현황 (2026-04-16)
- 실행 계획: [docs/day15-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day15-plan.md)
- 릴리즈 체크리스트:
  - [docs/day15-release-checklist.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day15-release-checklist.md)
- 운영 핸드북(배포/롤백/장애 대응):
  - [docs/day15-operations-handbook.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day15-operations-handbook.md)
- MVP 종료 기준 + v1 백로그:
  - [docs/day15-v1-backlog.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day15-v1-backlog.md)
- Day15 릴리즈 점검 스크립트:
  - [scripts/day15_release_readiness.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day15_release_readiness.sh)
  - [scripts/day15_go_live_check.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day15_go_live_check.sh) (원샷 점검)

### Day 15 실행
```bash
./scripts/day15_release_readiness.sh
./scripts/day15_go_live_check.sh .env
```

위 실행으로 CI 품질 게이트 + 릴리즈 문서/환경 점검을 함께 확인합니다.

## Day 16 진행 현황 (2026-04-18)
- 실행 계획: [docs/day16-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day16-plan.md)
- 실채널 relay + dedup/silence:
  - [monitoring/alert_webhook/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alert_webhook/server.py)
- Alertmanager 억제 규칙(inhibit):
  - [monitoring/alertmanager/alertmanager.yml](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/alertmanager/alertmanager.yml)
- mock PagerDuty sink:
  - [monitoring/mock_pagerduty/server.py](/Users/jin/Desktop/easy_ing/BlogSnap/monitoring/mock_pagerduty/server.py)
- Day16 데모:
  - [scripts/day16_real_channel_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day16_real_channel_demo.sh)

### Day 16 실행
```bash
./scripts/day16_real_channel_demo.sh
```

위 실행으로 warning은 webhook 채널, critical은 PagerDuty 이벤트 경로로 전달되고 중복 critical 알림이 silence window로 억제되는지 확인합니다.

## Day 17 진행 현황 (2026-04-19)
- 실행 계획: [docs/day17-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day17-plan.md)
- 인증/권한 코어:
  - [backend/app/core/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/auth.py)
- auth/project API:
  - [backend/app/api/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/auth.py)
  - [backend/app/api/projects.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/projects.py)
- 권한 적용 API:
  - [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
  - [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
  - [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
- Day17 데모:
  - [scripts/day17_auth_rbac_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day17_auth_rbac_demo.sh)

### Day 17 실행
```bash
./scripts/day17_auth_rbac_demo.sh
```

위 실행으로 owner 접근 허용, 타 사용자 cross-access 403 차단을 확인합니다.

## Day 18 진행 현황 (2026-04-21)
- 실행 계획: [docs/day18-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day18-plan.md)
- 예약 발행 스키마/생성 로직:
  - [backend/app/schemas/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/publish.py)
  - [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
- 예약 시간 우회 방지 실행 가드:
  - [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
- Day18 데모/테스트:
  - [scripts/day18_scheduled_publish_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day18_scheduled_publish_demo.sh)
  - [tests/test_scheduled_publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_scheduled_publish.py)

### Day 18 실행
```bash
./scripts/day18_scheduled_publish_demo.sh
```

위 실행으로 예약 시간 전 `RETRYING` 유지, 예약 시각 도달 후 `SUCCEEDED/PUBLISHED` 전이를 확인합니다.

## Day 19 진행 현황 (2026-04-22)
- 실행 계획: [docs/day19-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day19-plan.md)
- 멀티 프로바이더 확장:
  - [backend/app/models/enums.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/enums.py) (`tistory` provider 추가)
  - [db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql) (`provider_type` enum 확장)
- 발행 실행 분기 확장:
  - [backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py) (`mock/wordpress/tistory/live` 지원)
  - [backend/app/worker/publishers.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/publishers.py) (`publish_to_tistory` 추가)
- 환경/검증/데모:
  - [scripts/day12_env_check.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day12_env_check.sh) (tistory/live 점검 추가)
  - [scripts/day19_multi_provider_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day19_multi_provider_demo.sh)
- 테스트:
  - [tests/test_multi_provider_publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_multi_provider_publish.py)

### Day 19 실행
```bash
./scripts/day19_multi_provider_demo.sh
```

위 실행으로 동일 초고에 대해 `wordpress`와 `tistory` 발행 Job이 각각 독립 처리되고, mock URL에 provider 경로가 반영되는지 확인합니다.

## Day 20 진행 현황 (2026-04-23)
- 실행 계획: [docs/day20-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day20-plan.md)
- 초고 품질 점수화 로직:
  - [backend/app/services/draft_quality.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/services/draft_quality.py)
  - 평가 항목: 키워드 반영률, 본문 길이, 구조(헤딩), 감정톤 정합성
- 추천 API 추가:
  - [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
  - `GET /v1/drafts/recommend?project_id=...`
  - 추천 초고 + 후보 점수/근거 목록 반환
- 스키마/검증:
  - [backend/app/schemas/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/drafts.py)
  - [tests/test_draft_recommendation.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_draft_recommendation.py)
- Day20 데모:
  - [scripts/day20_quality_recommend_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day20_quality_recommend_demo.sh)

### Day 20 실행
```bash
./scripts/day20_quality_recommend_demo.sh
```

위 실행으로 최신 버전 초고 3안의 점수화 결과와 추천안이 정상 반환되는지 확인합니다.

## Day 21 진행 현황 (2026-04-24)
- 실행 계획: [docs/day21-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day21-plan.md)
- 예약 제어 API:
  - [backend/app/api/publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/publish.py)
  - `PATCH /v1/publish/{publish_job_id}/schedule`
  - `POST /v1/publish/{publish_job_id}/cancel`
- 예약 상태 모델 확장:
  - [backend/app/models/enums.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/enums.py) (`ScheduleStatus`)
  - [backend/app/models/entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py) (`schedule_status`, `scheduled_at`, `cancelled_at`)
  - [db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql)
- 워커 실행 가드:
  - [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py) (취소된 예약 실행 차단)
- Day21 테스트/데모:
  - [tests/test_scheduled_publish_controls.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_scheduled_publish_controls.py)
  - [scripts/day21_scheduling_control_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day21_scheduling_control_demo.sh)

### Day 21 실행
```bash
./scripts/day21_scheduling_control_demo.sh
```

위 실행으로 예약 시간 변경 시 즉시 실행 가능 전환과 예약 취소 후 실행 차단이 정상 동작하는지 확인합니다.

## Day 22 진행 현황 (2026-04-26)
- 실행 계획: [docs/day22-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day22-plan.md)
- 예약 재조정 로직:
  - [backend/app/worker/scheduler.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/scheduler.py)
  - 예약 시각 도달 건 `SCHEDULED -> READY` 전환
- 재조정 API:
  - [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
  - `POST /v1/jobs/reconcile-schedules?project_id=...`
- 워커 루프 통합:
  - [backend/app/worker/run_forever.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/run_forever.py)
  - 배치 실행 전 reconcile 단계 수행
- Day22 테스트/데모:
  - [tests/test_schedule_reconcile.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_schedule_reconcile.py)
  - [scripts/day22_schedule_reconcile_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day22_schedule_reconcile_demo.sh)

### Day 22 실행
```bash
./scripts/day22_schedule_reconcile_demo.sh
```

위 실행으로 예약 미래 건은 waiting 유지, 시각 도달 건은 activated 처리 후 정상 발행되는 흐름을 확인합니다.

## Day 23 진행 현황 (2026-04-28)
- 실행 계획: [docs/day23-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day23-plan.md)
- 워커 클레임 안정성 강화:
  - [backend/app/worker/runner.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/runner.py)
  - `claim_next_job`에 `FOR UPDATE SKIP LOCKED` 적용
- 실행 경로 일원화:
  - [backend/app/api/jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/jobs.py)
  - `run-next/run-batch`가 runner의 project 스코프 실행을 직접 사용
- Day23 테스트:
  - [tests/test_job_runner_project_scope.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_job_runner_project_scope.py)

### Day 23 검증
```bash
PYTHONPATH=. python3 -m pytest -q tests/test_job_runner_project_scope.py
```

위 검증으로 project 단위 실행 분리와 limit 처리 일관성을 확인합니다.

## Day 24 진행 현황 (2026-04-29)
- 실행 계획: [docs/day24-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day24-plan.md)
- Pydantic 스키마 설정 최신화:
  - [auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/auth.py)
  - [drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/drafts.py)
  - [jobs.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/jobs.py)
  - [publish.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/publish.py)
  - [projects.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/projects.py)
- `class Config`를 `ConfigDict`로 전환해 V2 deprecation warning 노이즈를 줄였습니다.

### Day 24 검증
```bash
./scripts/day13_test_suite.sh
```

위 검증에서 기존 기능 회귀 없이 테스트가 통과하는지 확인합니다.

## Day 25 진행 현황 (2026-04-30)
- 실행 계획: [docs/day25-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day25-plan.md)
- 인증 토큰 고도화:
  - [auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/auth.py) (`access`/`refresh` 타입 분리)
  - [auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/auth.py) (`/refresh`, `/logout`)
  - [auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/auth.py)
- 세션 저장:
  - [entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py) (`AuthSession`)
  - [0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql) (`auth_sessions`)
- Day25 테스트/데모:
  - [test_auth_refresh_logout.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_auth_refresh_logout.py)
  - [day25_auth_refresh_logout_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day25_auth_refresh_logout_demo.sh)

### Day 25 실행
```bash
./scripts/day25_auth_refresh_logout_demo.sh
```

위 실행으로 login -> refresh rotate -> logout revoke -> refresh 차단(401) 흐름을 확인합니다.

## Day 26 기록 (2026-05-01)
- 프론트엔드 E2E 통합을 시도했으나(`feat(frontend): Day26 E2E UI integration for blog generation flow`) 같은 날 되돌림(revert) 처리되었습니다.
- 실제 프론트엔드 통합은 Day27에서 asset 업로드 흐름과 함께 다시 작업되었습니다.

## Day 27 진행 현황 (2026-05-02)
- 실행 계획: [docs/day27-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day27-plan.md)
- 목표: 프론트 이미지 선택을 백엔드 asset 저장 흐름과 연결 (Day26에서 되돌려진 프론트 통합 재작업)
- 자산 업로드 API:
  - [backend/app/api/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/assets.py) (`POST /v1/assets/upload` multipart, `GET /v1/assets`)
- 모델/스키마 확장:
  - [backend/app/models/entities.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/entities.py)
  - [backend/app/models/enums.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/models/enums.py)
  - [backend/app/schemas/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/assets.py)
- 프론트 통합: [frontend/src/App.tsx](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/src/App.tsx) (업로드 후 `image_asset_id` 전달)
- Day27 테스트: [tests/test_assets_api.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_assets_api.py)

### Day 27 검증
```bash
PYTHONPATH=. python3 -m pytest -q tests/test_assets_api.py
```

## Day 28 진행 현황 (2026-05-03)
- 실행 계획: [docs/day28-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day28-plan.md)
- 목표: asset 업로드/사용 흐름의 운영 안전성 강화
- 허용 타입/최대 용량 검증: [backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py) (`ASSET_ALLOWED_CONTENT_TYPES`, `ASSET_MAX_BYTES`)
- 삭제 API: [backend/app/api/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/assets.py) (`DELETE /v1/assets/{asset_id}`)
- draft 생성 시 `image_asset_id` 상태/소유 검증: [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
- Day28 테스트: [tests/test_draft_asset_validation.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_draft_asset_validation.py)

### Day 28 검증
```bash
PYTHONPATH=. python3 -m pytest -q tests/test_assets_api.py tests/test_draft_asset_validation.py
```

## Day 29 진행 현황 (2026-05-04)
- 실행 계획: [docs/day29-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day29-plan.md)
- 목표: soft-delete된 asset의 장기 누적 방지를 위한 purge 관리 기능 추가
- `POST /v1/assets/cleanup` (project 단위 purge), `ASSET_DELETED_RETENTION_HOURS` 설정: [backend/app/api/assets.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/assets.py), [backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py)
- Day29 테스트: [tests/test_assets_api.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_assets_api.py) (`test_cleanup_purges_old_deleted_assets`)

## Day 30 진행 현황 (2026-05-05)
- 실행 계획: [docs/day30-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day30-plan.md)
- 목표: Day29 cleanup API를 운영 자동화 가능한 실행 경로로 확장
- 공통 purge 서비스 분리: [backend/app/services/asset_cleanup.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/services/asset_cleanup.py) (`purge_deleted_assets_for_project`, `purge_deleted_assets_all_projects`)
- 전체 프로젝트 일괄 정리 스크립트: [scripts/day30_asset_cleanup_run.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day30_asset_cleanup_run.sh)
- Day30 테스트: [tests/test_asset_cleanup_service.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_asset_cleanup_service.py)

### Day 30 실행
```bash
./scripts/day30_asset_cleanup_run.sh
```

## Day 31 진행 현황 (2026-05-06)
- 실행 계획: [docs/day31-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day31-plan.md)
- 목표: Day30 자산 정리 스크립트를 정기 실행 가능한 워크플로우로 편입
- GitHub Actions workflow(`workflow_dispatch` + `schedule`, `retention_hours` 입력 지원): [.github/workflows/day31-asset-cleanup.yml](/Users/jin/Desktop/easy_ing/BlogSnap/.github/workflows/day31-asset-cleanup.yml)

## Day 32 진행 현황 (2026-05-07)
- 실행 계획: [docs/day32-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day32-plan.md)
- 목표: asset cleanup 실행 결과를 리포트 파일 + workflow artifact로 보관
- 리포트 생성 스크립트: [scripts/day32_asset_cleanup_report.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day32_asset_cleanup_report.sh)
- artifact 업로드 workflow: [.github/workflows/day32-asset-cleanup-report.yml](/Users/jin/Desktop/easy_ing/BlogSnap/.github/workflows/day32-asset-cleanup-report.yml)

## Day 33 진행 현황 (2026-05-08)
- 실행 계획: [docs/day33-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day33-plan.md)
- 목표: cleanup 리포트 파이프라인 견고화
- JSON payload 추출 안정화, Markdown 요약 리포트, workflow Step Summary 게시, JSON+Markdown artifact 동시 업로드: [scripts/day32_asset_cleanup_report.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day32_asset_cleanup_report.sh)

## Day 34 진행 현황 (2026-05-09)
- 실행 계획: [docs/day34-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day34-plan.md)
- 목표: 배포 D-체크리스트 핵심 게이트를 스크립트로 자동 실행
- [scripts/day34_deploy_dry_run.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day34_deploy_dry_run.sh) → `tmp/reports/deploy-dry-run-*.md` 생성
- 체크리스트 문서: [docs/deploy-checklist-d3-d1.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/deploy-checklist-d3-d1.md)

### Day 34 실행
```bash
./scripts/day34_deploy_dry_run.sh
```

## Day 35 진행 현황 (2026-05-10)
- 실행 계획: [docs/day35-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day35-plan.md)
- 목표: 배포 직전 승인 판단을 위한 원클릭 게이트 스크립트 제공
- [scripts/day35_release_candidate_gate.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day35_release_candidate_gate.sh) (dry-run + frontend build + compile 검증 묶음) → `tmp/reports/release-candidate-gate-*.md`

## Day 36 진행 현황 (2026-05-11)
- 실행 계획: [docs/day36-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day36-plan.md)
- 목표: RC 게이트 결과를 사람이 읽는 Markdown뿐 아니라 자동 판정 가능한 JSON으로 기록
- [scripts/day35_release_candidate_gate.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day35_release_candidate_gate.sh)에 단계별 `passed/failed/skipped` JSON 상태파일 생성 추가

## Day 37 진행 현황 (2026-05-12)
- 실행 계획: [docs/day37-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day37-plan.md)
- 목표: Day36 RC gate JSON을 기반으로 릴리즈 가능 여부 자동 판정
- 최신 RC JSON 자동 탐색, 리포트 staleness(`MAX_AGE_HOURS`) 검증, `status=passed` 및 단계별 실패 여부 검증: [scripts/day37_release_decision_gate.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day37_release_decision_gate.sh)

### Day 37 실행
```bash
./scripts/day37_release_decision_gate.sh tmp/reports
```

## Day 38 진행 현황 (2026-05-15)
- 실행 계획: [docs/day38-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day38-plan.md)
- 목표: 배포 전 체크를 재현 가능한 단일 파이프라인 게이트로 통합
- 배포 환경(dev/staging/prod) 변수 매트릭스: [docs/day38-deploy-env-matrix.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day38-deploy-env-matrix.md)
- GitHub Environments/Secrets 운영 가이드: [docs/day38-github-environments.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day38-github-environments.md)
- 마이그레이션 check/apply 모드가 있는 배포 게이트: [scripts/day38_deploy_pipeline_gate.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day38_deploy_pipeline_gate.sh)

### Day 38 실행
```bash
MIGRATION_MODE=check ./scripts/day38_deploy_pipeline_gate.sh .env.example tmp/reports
```

## Day 39 진행 현황 (2026-05-16)
- 실행 계획: [docs/day39-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day39-plan.md)
- 목표: 워드프레스/티스토리 실계정 연동 전 리허설 단계 표준화
- provider별 필수 키 점검, placeholder(예시값) 감지, `dry-run`(mock 리허설)/`real-run`(실업로드) 모드 분리: [scripts/day39_provider_rehearsal.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day39_provider_rehearsal.sh)

### Day 39 실행 (안전 모드)
```bash
REHEARSAL_MODE=dry-run ./scripts/day39_provider_rehearsal.sh .env.example tmp/reports
```

## Day 40 진행 현황 (2026-05-17)
- 실행 계획: [docs/day40-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day40-plan.md)
- 목표: 운영 알림 품질을 위한 SLI/SLO 기준과 점검 자동화 추가
- SLI/SLO 문서: [docs/day40-sli-slo.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day40-sli-slo.md)
- 알림 임계치/튜닝 가이드: [docs/day40-alert-tuning.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day40-alert-tuning.md)
- 점검 스크립트: [scripts/day40_monitoring_tuning_check.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day40_monitoring_tuning_check.sh)

### Day 40 실행
```bash
./scripts/day40_monitoring_tuning_check.sh .env.example tmp/reports
```

## Day 41 진행 현황 (2026-05-18)
- 실행 계획: [docs/day41-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day41-plan.md)
- 목표: 배포 전 장애 복구 리허설 루틴 표준화
- DB/Queue/Provider 3개 복구 시나리오 자동 실행: [scripts/day41_gameday_recovery.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day41_gameday_recovery.sh)
- 게임데이 런북: [docs/day41-gameday-runbook.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day41-gameday-runbook.md)

### Day 41 실행
```bash
SCENARIO=all ./scripts/day41_gameday_recovery.sh .env.example tmp/reports
```

## Day 42 진행 현황 (2026-05-19)
- 실행 계획: [docs/day42-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day42-plan.md)
- 목표: Go/No-Go 결정을 위한 최종 승인 패키지 완료
- 최종 게이트 스크립트: [scripts/day42_go_live_decision.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day42_go_live_decision.sh)
- Go/No-Go 회의록 템플릿: [docs/day42-go-live-minutes-template.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day42-go-live-minutes-template.md)
- 배포 후 24시간 모니터링 계획: [docs/day42-post-release-24h-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day42-post-release-24h-plan.md)

### Day 42 실행
```bash
./scripts/day42_go_live_decision.sh .env.example tmp/reports
```

## Day 43 진행 현황 (2026-05-20)
- 실행 계획: [docs/day43-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day43-plan.md)
- 목표: 배포 직후 운영 상태를 재현 가능한 리포트로 고정하고 리트로 기반 마련
- queue/metrics 스냅샷 스크립트: [scripts/day43_post_launch_snapshot.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day43_post_launch_snapshot.sh)
- post-launch 리트로 템플릿: [docs/day43-retro-template.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day43-retro-template.md)

### Day 43 실행
```bash
./scripts/day43_post_launch_snapshot.sh .env.example tmp/reports
```

## Day 44 진행 현황 (2026-05-21)
- 실행 계획: [docs/day44-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day44-plan.md)
- 목표: Day42~43 운영 리포트를 묶어 안정화 추세를 빠르게 판단
- 최신 운영 리포트 자동 집계/요약 스크립트: [scripts/day44_stabilization_trend_report.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day44_stabilization_trend_report.sh)
- 가이드: [docs/day44-stabilization-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day44-stabilization-guide.md)

### Day 44 실행
```bash
./scripts/day44_stabilization_trend_report.sh tmp/reports tmp/reports
```

## Day 45 진행 현황 (2026-05-22)
- 실행 계획: [docs/day45-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day45-plan.md)
- 목표: Day42~44 운영 결과를 단일 최신 리포트(`release-health`)로 제공
- [scripts/day45_release_health_bundle.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day45_release_health_bundle.sh) → `release-health-<ts>.md/json` + `release-health-latest.md/json`
- 가이드: [docs/day45-release-health-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day45-release-health-guide.md)

### Day 45 실행
```bash
./scripts/day45_release_health_bundle.sh tmp/reports tmp/reports
```

## Day 46 진행 현황 (2026-05-23)
- 실행 계획: [docs/day46-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day46-plan.md)
- 목표: alert forwarding 품질/노이즈 비율을 수치로 확인하고 튜닝 제안 자동 생성
- [scripts/day46_alert_noise_review.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day46_alert_noise_review.sh), 가이드: [docs/day46-alert-noise-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day46-alert-noise-guide.md)

### Day 46 실행
```bash
./scripts/day46_alert_noise_review.sh .env.example tmp/reports
```

## Day 47 진행 현황 (2026-05-24)
- 실행 계획: [docs/day47-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day47-plan.md)
- 목표: release-health/Day46 신호 기반 장애 징후 감지 및 Day41 복구 시나리오 자동 연계
- [scripts/day47_incident_watcher.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day47_incident_watcher.sh), 가이드: [docs/day47-incident-response-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day47-incident-response-guide.md)

### Day 47 실행
```bash
./scripts/day47_incident_watcher.sh .env.example tmp/reports
```

## Day 48 진행 현황 (2026-05-25)
- 실행 계획: [docs/day48-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day48-plan.md)
- 목표: 배포 승인/차단 결정을 정량 신호 기반으로 자동화
- [scripts/day48_deploy_approval_gate.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day48_deploy_approval_gate.sh) (block reason 자동 기록), 가이드: [docs/day48-approval-policy.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day48-approval-policy.md)

### Day 48 실행
```bash
./scripts/day48_deploy_approval_gate.sh .env.example tmp/reports
```

## Day 49 진행 현황 (2026-05-27)
- 실행 계획: [docs/day49-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day49-plan.md)
- 목표: 운영 신호를 읽어 리트로 초안(md/json) + 액션 아이템 자동 생성
- [scripts/day49_retro_autofill.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day49_retro_autofill.sh), 가이드: [docs/day49-retro-automation-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day49-retro-automation-guide.md)

### Day 49 실행
```bash
./scripts/day49_retro_autofill.sh tmp/reports tmp/reports
```

## Day 50 진행 현황 (2026-05-28)
- 실행 계획: [docs/day50-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day50-plan.md)
- 목표: Day45~49 운영 자동화를 단일 오케스트레이션 스크립트로 통합
- [scripts/day50_ops_suite.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day50_ops_suite.sh), 가이드: [docs/day50-ops-suite-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day50-ops-suite-guide.md)

### Day 50 실행
```bash
./scripts/day50_ops_suite.sh .env.example tmp/reports
```

## Day 51 진행 현황 (2026-05-31)
- 실행 계획: [docs/day51-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day51-plan.md)
- 목표: Day50 운영 스위트 결과를 상태 배지(svg)와 요약 파일로 노출
- [scripts/day51_ops_status_badge.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day51_ops_status_badge.sh), 가이드: [docs/day51-status-badge-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day51-status-badge-guide.md)

### Day 51 실행
```bash
./scripts/day51_ops_status_badge.sh tmp/reports tmp/reports
```

## Day 52 진행 현황 (2026-05-31)
- 실행 계획: [docs/day52-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day52-plan.md)
- 목표: 운영 자동화 산출물의 최신 위치를 단일 manifest로 정리
- [scripts/day52_ops_report_manifest.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day52_ops_report_manifest.sh) (Day45~51 최신 json 포인터 자동 수집), 가이드: [docs/day52-manifest-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day52-manifest-guide.md)

### Day 52 실행
```bash
./scripts/day52_ops_report_manifest.sh tmp/reports tmp/reports
```

## Day 53 진행 현황 (2026-06-06)
- 실행 계획: [docs/day53-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day53-plan.md)
- 목표: lightweight deploy check와 운영 자동화 리포트를 결합해 최종 배포 readiness 판정
- [scripts/day53_deploy_readiness_report.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day53_deploy_readiness_report.sh) (`check_deploy_ready.sh` + Day52 manifest + Day48 approval + Day51 ops status 결합, `ready`/`blocked` 판정), 가이드: [docs/day53-readiness-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day53-readiness-guide.md)

### Day 53 실행
```bash
./scripts/day53_deploy_readiness_report.sh tmp/reports tmp/reports
```

## Day 54 진행 현황 (2026-06-06)
- 실행 계획: [docs/day54-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day54-plan.md)
- 목표: 오래되었거나 오탐된 운영 신호로 막힌 deploy readiness를 최신 리포트 기준으로 재계산
- Day45 release-health status 추출 오탐 수정, Day45→47→48→52→53 순서로 refresh: [scripts/day54_readiness_refresh.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day54_readiness_refresh.sh), 가이드: [docs/day54-readiness-refresh-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day54-readiness-refresh-guide.md)

### Day 54 실행
```bash
./scripts/day54_readiness_refresh.sh .env.example tmp/reports
```

## Day 55 진행 현황 (2026-06-08)
- 실행 계획: [docs/day55-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day55-plan.md)
- 목표: `ready` 상태의 deploy readiness를 배포 승인용 lock snapshot으로 고정
- git branch/commit 및 readiness/소스 checksum 기록, `ready`가 아니면 lock 생성 실패 처리: [scripts/day55_release_lock_snapshot.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day55_release_lock_snapshot.sh), 가이드: [docs/day55-release-lock-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day55-release-lock-guide.md)

### Day 55 실행
```bash
./scripts/day55_release_lock_snapshot.sh tmp/reports tmp/reports
```

## Day 56 진행 현황 (2026-06-10)
- 실행 계획: [docs/day56-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day56-plan.md)
- 목표: Day55 release lock을 최신 HEAD 기준으로 갱신하고 배포 인수인계용 검증 패키지 생성
- lock commit/branch와 현재 HEAD 비교, readiness/checksum 재검증: [scripts/day56_release_handoff_package.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day56_release_handoff_package.sh), 가이드: [docs/day56-release-handoff-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day56-release-handoff-guide.md)

### Day 56 실행
```bash
./scripts/day56_release_handoff_package.sh tmp/reports tmp/reports
```

## Day 57 진행 현황 (2026-06-11)
- 실행 계획: [docs/day57-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day57-plan.md)
- 목표: 배포 승인에 필요한 최신 evidence 파일들을 하나의 인덱스로 통합
- Day53/55/56/52/51/48/release-health evidence 수집, handoff commit/branch와 현재 HEAD 일치 검증: [scripts/day57_release_evidence_index.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day57_release_evidence_index.sh), 가이드: [docs/day57-release-evidence-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day57-release-evidence-guide.md)

### Day 57 실행
```bash
./scripts/day57_release_evidence_index.sh tmp/reports tmp/reports
```

## Day 58 진행 현황 (2026-06-12)
- 실행 계획: [docs/day58-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day58-plan.md)
- 목표: Day57 evidence를 기준으로 배포 실행 직전 receipt 생성
- evidence commit/branch와 현재 HEAD 비교, `dry-run`/`execute` 액션 구분(`execute`는 `CONFIRM_DEPLOY=yes` 필요): [scripts/day58_deployment_execution_receipt.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day58_deployment_execution_receipt.sh), 가이드: [docs/day58-deployment-receipt-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day58-deployment-receipt-guide.md)

### Day 58 실행
```bash
DEPLOY_TARGET=staging DEPLOY_ACTION=dry-run \
  ./scripts/day58_deployment_execution_receipt.sh tmp/reports tmp/reports
```

## Day 59 진행 현황 (2026-06-13)
- 실행 계획: [docs/day59-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day59-plan.md)
- 목표: Day58 receipt가 최신 커밋/배포 승인 evidence에 맞게 생성되었는지 검증
- receipt·evidence의 commit/branch/action/target을 현재 HEAD와 비교: [scripts/day59_post_deploy_verification.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day59_post_deploy_verification.sh), 가이드: [docs/day59-post-deploy-verification-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day59-post-deploy-verification-guide.md)

### Day 59 실행
```bash
DEPLOY_TARGET=staging DEPLOY_ACTION=dry-run \
  ./scripts/day59_post_deploy_verification.sh tmp/reports tmp/reports
```

## Day 60 진행 현황 (2026-06-14)
- 실행 계획: [docs/day60-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day60-plan.md)
- 목표: Day59 verification 이후 실제 배포 대상 API가 최소 동작 상태인지 확인
- `/health`, `/health/ready`, 로그인/프로젝트 생성, queue summary, metrics endpoint, worker 컨테이너 상태(optional) 확인: [scripts/day60_post_deploy_smoke_check.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day60_post_deploy_smoke_check.sh), 가이드: [docs/day60-post-deploy-smoke-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day60-post-deploy-smoke-guide.md)

### Day 60 실행
```bash
API_URL=http://127.0.0.1:8000 DEPLOY_TARGET=staging DEPLOY_ACTION=dry-run \
  ./scripts/day60_post_deploy_smoke_check.sh tmp/reports tmp/reports
```

## Day 61 진행 현황 (2026-06-15)
- 실행 계획: [docs/day61-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day61-plan.md)
- 목표: 프론트/백엔드 URL을 혼동하지 않고 웹 미리보기를 열 수 있도록 자동 점검
- Vite `/api` proxy, 프론트 `.env.example` proxy 변수, 백엔드 `/` 404 기대값 vs `/health`, 프론트 `http://localhost:5173/` 렌더링, `npm run build` 확인: [scripts/day61_preview_readiness_check.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day61_preview_readiness_check.sh), 가이드: [docs/day61-preview-readiness-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day61-preview-readiness-guide.md)
- 같은 시점에 프론트 미리보기 proxy가 실제 백엔드 포트와 어긋난 문제를 수정 (`fix(frontend): align preview proxy with backend port`)

### Day 61 실행
```bash
API_URL=http://127.0.0.1:8000 FRONTEND_URL=http://127.0.0.1:5173 \
  ./scripts/day61_preview_readiness_check.sh tmp/reports tmp/reports
```

## Day 62 진행 현황 (2026-06-17)
- 실행 계획: [docs/day62-plan.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day62-plan.md)
- 목표: 사용자가 웹 미리보기를 직접 수동 테스트할 때 그대로 따라갈 수 있는 UAT 세션 패킷 제공
- 로그인/프로젝트 생성/초고 생성/재생성/선택/발행 수동 테스트 절차 + 이슈 기록 템플릿을 자동 생성: [scripts/day62_uat_session_packet.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day62_uat_session_packet.sh), 가이드: [docs/day62-uat-session-guide.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/day62-uat-session-guide.md)

### Day 62 실행
```bash
API_URL=http://127.0.0.1:8000 FRONTEND_URL=http://127.0.0.1:5173 \
  ./scripts/day62_uat_session_packet.sh tmp/reports tmp/reports
```

## 다음 단계 (2026-08-13 기준)
- 마지막 실행 리포트(`tmp/reports/day62-uat-session-latest.md`, 2026-06-17 기준)는 `uat_status: ready`로, 자동화된 배포/프리뷰 준비 점검은 모두 통과한 상태입니다.
- 아직 실행되지 않은 마지막 단계는 Day62 UAT 패킷의 `uat-01`부터 시작하는 **실제 브라우저 수동 테스트**입니다.

## Day 63 진행 현황 (2026-08-13) — 실제 AI 초고 생성 연결
- 실제 브라우저로 Day62 UAT 시나리오를 끝까지 실행하던 중, `초고 생성`이 항상 성공하는데도 본문 내용을 확인해보니 [backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py)의 `_build_markdown()`이 **OpenAI/AI 호출 없이 고정 템플릿 문구만 반환**하고 있었음을 발견했습니다. Day1의 Streamlit 경로([blogsnap/ai_writer.py](/Users/jin/Desktop/easy_ing/BlogSnap/blogsnap/ai_writer.py))만 실제로 OpenAI를 호출했고, Day2 이후 새로 만든 FastAPI 백엔드 경로는 이 핵심 기능이 자리표시자로 남아있었습니다.
- 비용 절감을 위해 OpenAI 대신 **Google Gemini 무료 티어**를 연결하기로 결정:
  - Gemini 연동 서비스: [backend/app/services/gemini_writer.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/services/gemini_writer.py) (`google-genai` SDK, 이미지+키워드+감정강도로 초고 2~3개를 JSON으로 생성)
  - 실행 모드 분기: [backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py)에 `WORKER_DRAFT_MODE` (`mock`/`gemini`) 추가, `gemini` 모드에서는 업로드된 asset 이미지를 읽어 함께 전달
  - 설정 추가: [backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py) (`worker_draft_mode`, `gemini_api_key`, `gemini_model`)
  - 재생성 버그 수정: [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py) `regenerate_draft`가 항상 기본값(`키워드`/`설명`/감정 0)으로 재생성하던 것을 고쳐, `draft.source_job_id`를 통해 원래 생성 요청(키워드/감정/글종류/이미지)을 재사용하도록 수정
  - 의존성: [requirements.txt](/Users/jin/Desktop/easy_ing/BlogSnap/requirements.txt) (`google-genai`), [docker-compose.dev.yml](/Users/jin/Desktop/easy_ing/BlogSnap/docker-compose.dev.yml) (`api`/`worker`에 `WORKER_DRAFT_MODE`/`GEMINI_API_KEY`/`GEMINI_MODEL` 환경변수 전달)
- 기본값은 여전히 `mock`이라 기존 테스트(`tests/`, 24건)는 회귀 없이 그대로 통과합니다. 실제 AI 생성을 쓰려면 `.env`에 `WORKER_DRAFT_MODE=gemini`와 [Google AI Studio](https://aistudio.google.com/apikey)에서 발급한 `GEMINI_API_KEY`를 설정하고 `docker compose -f docker-compose.dev.yml up -d --build api worker`로 재기동합니다.
- **후속 수정**: 기본 모델 `gemini-2.5-flash`가 신규 발급 키에는 `404 no longer available to new users`로 막혀 있어 실제 생성이 계속 mock 콘텐츠로 조용히 대체되고 있었습니다. 실제 Gemini API로 사용 가능한 모델 목록을 조회해 `gemini-3.5-flash`로 기본값을 교체([backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py), `.env`, `.env.example`)했고, DB에 저장된 실제 생성 결과로 서로 다른 제목/본문이 나오는 것까지 확인했습니다.
- **테스트 격리**: 로컬 `.env`의 `WORKER_DRAFT_MODE=gemini`를 pytest가 그대로 물려받아 실제 API를 호출하며 5분 이상 걸리고 일부 실패하는 문제 발견 → [tests/conftest.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/conftest.py)에서 테스트는 항상 `mock` 모드로 강제 고정하도록 수정.
- **글 유형별 문체 강화**: 리뷰/설명형/소감문 각각에 대해 "평가 중심/장단점 비교" · "객관적 정보 전달, 개인 일화 자제" · "개인 경험과 감상 위주 에세이"로 구체적인 작성 방향 지침을 프롬프트에 추가([backend/app/services/gemini_writer.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/services/gemini_writer.py)). 감정 강도는 "톤의 가장 큰 기준"으로 프롬프트에 명시.
- Gemini 무료 티어는 모델당 **일일 20회** 요청 제한이 있어(`gemini-3.5-flash` 기준), 자체 테스트 중 한도 소진 시 `429 RESOURCE_EXHAUSTED`가 발생합니다. 자정(태평양시) 리셋 후 재시도하거나 유료 플랜으로 전환이 필요합니다.
- **UI 스타일 재조정**: Toss 스타일(파스텔/그라데이션/필 버튼) 대신 네이버 블로그에 가까운 그린(#03c75a) 액센트 + 화이트/헤어라인 보더 기반의 미니멀한 스타일로 교체([frontend/src/styles.css](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/src/styles.css)).
- **배포 전 시크릿 점검**: `.dockerignore`가 없어 `.env`(실제 API 키 포함)가 그대로 Docker 이미지에 baked-in 되고 있던 것을 발견 → [.dockerignore](/Users/jin/Desktop/easy_ing/BlogSnap/.dockerignore) 추가로 차단. `AUTH_SECRET_KEY`가 기본값(`change-me-dev-secret`)인 채로 프로덕션에 뜨는 것을 막기 위해 `APP_ENV=production`일 때 기본값/약한 키면 서버가 기동을 거부하도록 검증 추가([backend/app/core/config.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/core/config.py)). 배포 전 체크리스트는 [docs/security-secrets-checklist.md](/Users/jin/Desktop/easy_ing/BlogSnap/docs/security-secrets-checklist.md) 참고. git 이력 전체(`git log --all -p`)에서 `.env`/실제 키 문자열이 커밋된 적 없는 것과, GitHub Actions 워크플로우가 Docker 이미지를 어디에도 push하지 않는 것도 확인함 — 공개 저장소이지만 실제 유출은 없었음.
- **사용자별 Gemini API 키**: 서버 하나의 키를 모든 사용자가 나눠 쓰면 운영자에게 비용/한도 부담이 몰리는 구조라, 각자 자기 키를 연결해서 쓰도록 전환.
  - `users.gemini_api_key_encrypted` 컬럼 추가([db/migrations/0001_init.sql](/Users/jin/Desktop/easy_ing/BlogSnap/db/migrations/0001_init.sql)), `AUTH_SECRET_KEY`에서 파생한 키로 Fernet 대칭암호화 저장/복호화([backend/app/services/secret_crypto.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/services/secret_crypto.py)) — DB가 유출돼도 키가 평문으로 노출되지 않음
  - `PUT` / `DELETE /v1/auth/me/gemini-key`로 연결/해제, `GET /v1/auth/me`는 연결 여부(`gemini_key_connected`)만 반환하고 **키 값 자체는 어떤 응답에도 절대 포함하지 않음**([backend/app/api/auth.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/auth.py))
  - 초고 생성은 이제 프로젝트 소유자가 연결한 키로만 동작하고, 서버 공용 `GEMINI_API_KEY`는 완전히 제거([backend/app/worker/executor.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/worker/executor.py)). 키 미연결 시 "Gemini API 키가 연결되어 있지 않습니다" 에러로 명확히 실패
  - 프론트에 키 연결/해제 UI 추가([frontend/src/App.tsx](/Users/jin/Desktop/easy_ing/BlogSnap/frontend/src/App.tsx)) — 한 번 연결하면 이후 요청은 별도 입력 없이 저장된 키로 계속 동작
  - 곁들여 `run-next` 실패 시 프론트가 "성공"으로 잘못 표시하던 것도 같이 수정(실제 job 상태/에러 메시지를 확인하도록 변경)
  - 테스트: [tests/test_user_gemini_key.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_user_gemini_key.py) (암호화 왕복, 연결/해제, 키 미연결 시 실패). 실제 API로 연결→생성 end-to-end까지 curl로 검증 완료.
