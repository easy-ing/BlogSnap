# Backend (Day 10 Alert Delivery)

## Run
```bash
uvicorn backend.app.main:app --reload --port 8000
```

## Required env
- `DATABASE_URL` (default: `postgresql+psycopg://blogsnap:blogsnap@localhost:55432/blogsnap`)
- `WORKER_PUBLISH_MODE` (`mock` or `wordpress`)
- `WORKER_MOCK_PUBLISH_BASE_URL` (mock mode URL prefix)
- `WORKER_POLL_SECONDS` (daemon polling interval)
- `WORKER_BATCH_SIZE` (jobs per poll)
- `LOG_LEVEL` (`INFO`, `DEBUG`, ...)
- `PROMETHEUS_ENABLED` (`true`/`false`)
- `GRAFANA_ADMIN_PASSWORD` (default `admin`)
- `ALERT_WEBHOOK_PORT` (default `5001`, alert-webhook receiver)
- `ALERT_WEBHOOK_LOG_PATH` (default `/data/alerts.jsonl`)
- `ALERT_FORWARD_WEBHOOK_URL` (optional, Slack incoming webhook URL)
- `ALERT_FORWARD_TIMEOUT_SECONDS` (default `5`)
- `WORDPRESS_BASE_URL`, `WORDPRESS_USERNAME`, `WORDPRESS_APP_PASSWORD` (wordpress mode)
- `WORKER_PUBLISH_DEFAULT_TAGS` (comma-separated)

## Endpoints (initial)
- `GET /health`
- `GET /health/ready`
- `GET /health/metrics`
- `POST /v1/drafts/generate`
- `GET /v1/drafts?project_id=...`
- `POST /v1/drafts/{draft_id}/regenerate`
- `POST /v1/drafts/{draft_id}/select`
- `POST /v1/publish`
- `GET /v1/publish/{publish_job_id}`
- `GET /v1/jobs/{job_id}`
- `POST /v1/jobs/{job_id}/run`
- `POST /v1/jobs/run-next`
- `POST /v1/jobs/run-batch?limit=10`
- `GET /v1/jobs/queue-summary`

## Worker
Run next pending/retrying job once:
```bash
PYTHONPATH=. python3 -m backend.app.worker.run_once
```

Run daemon loop:
```bash
PYTHONPATH=. python3 -m backend.app.worker.run_forever
```

Day6 demo:
```bash
./scripts/db_reset.sh
./scripts/day6_run_demo.sh
```

Day7 stack run + smoke test:
```bash
./scripts/day7_run_stack.sh
```

Day8 observability demo:
```bash
./scripts/day8_observability_demo.sh
```

Day9 observability+ demo:
```bash
./scripts/day9_observability_plus_demo.sh
```

Day10 alert delivery demo:
```bash
./scripts/day10_alert_delivery_demo.sh
```

Day11 webhook relay demo:
```bash
./scripts/day11_webhook_relay_demo.sh
```
