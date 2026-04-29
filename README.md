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
- `WORKER_PUBLISH_MODE` (`mock` / `wordpress` / `tistory` / `live`)
- `WORKER_POLL_SECONDS`, `WORKER_BATCH_SIZE`
- `LOG_LEVEL`
- `PROMETHEUS_ENABLED`
- `GRAFANA_ADMIN_PASSWORD`
- `WORDPRESS_BASE_URL`, `WORDPRESS_USERNAME`, `WORDPRESS_APP_PASSWORD` (wordpress/live 모드 시)
- `TISTORY_API_URL`, `TISTORY_ACCESS_TOKEN`, `TISTORY_BLOG_NAME` (tistory/live 모드 시)
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
