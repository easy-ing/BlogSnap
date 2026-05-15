# Day38 GitHub Environments and Secrets

## Environments
- `dev`
- `staging`
- `production`

## Required Repository Secrets
- `OPENAI_API_KEY`
- `DATABASE_URL`
- `WORKER_PUBLISH_MODE`
- `ALERT_FORWARD_TIMEOUT_SECONDS`

## Optional Provider Secrets
- `WORDPRESS_API_URL`
- `WORDPRESS_USERNAME`
- `WORDPRESS_APP_PASSWORD`
- `TISTORY_ACCESS_TOKEN`
- `TISTORY_BLOG_NAME`

## Alert Webhook Secrets
- `ALERT_FORWARD_WEBHOOK_URL_WARNING`
- `ALERT_FORWARD_WEBHOOK_URL_CRITICAL`

## Deployment Safety Rules
- `production` 환경은 reviewer 승인 필수
- 배포 전 `day37_release_decision_gate.sh` 통과 필수
- `MIGRATION_MODE=check` 선실행 후 `apply` 진행
- 실패 시 즉시 중단, 리포트 아티팩트 확인 후 재시도

## Suggested Workflow Order
1. CI (`.github/workflows/ci.yml`)
2. RC Gate (`scripts/day35_release_candidate_gate.sh`)
3. Release Decision (`scripts/day37_release_decision_gate.sh`)
4. Deploy Pipeline Gate (`scripts/day38_deploy_pipeline_gate.sh`)
