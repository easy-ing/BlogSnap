# Day38 Deploy Env Matrix

## Environment Targets

| Key | Development | Staging | Production |
| --- | --- | --- | --- |
| `APP_ENV` | `development` | `staging` | `production` |
| `DATABASE_URL` | local postgres | managed or dedicated staging DB | managed production DB |
| `OPENAI_API_KEY` | test key | staging key | production key |
| `WORKER_PUBLISH_MODE` | `mock` | `tistory` or `wordpress` (private channel) | `live` |
| `ALERT_FORWARD_TIMEOUT_SECONDS` | `3` | `5` | `5` |
| `ALERT_FORWARD_WEBHOOK_URL_WARNING` | optional | required | required |
| `ALERT_FORWARD_WEBHOOK_URL_CRITICAL` | optional | required | required |
| `WORDPRESS_API_URL` | optional | required if provider used | required if provider used |
| `WORDPRESS_USERNAME` | optional | required if provider used | required if provider used |
| `WORDPRESS_APP_PASSWORD` | optional | required if provider used | required if provider used |
| `TISTORY_ACCESS_TOKEN` | optional | required if provider used | required if provider used |
| `TISTORY_BLOG_NAME` | optional | required if provider used | required if provider used |

## Gate Policy
- `dev`: `MIGRATION_MODE=check` 권장
- `staging`: `MIGRATION_MODE=apply`로 배포 리허설
- `prod`: 먼저 `check`, 승인 후 `apply`

## Validation Command
```bash
MIGRATION_MODE=check ./scripts/day38_deploy_pipeline_gate.sh .env.example tmp/reports
```
