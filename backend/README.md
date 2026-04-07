# Backend (Day 6 Worker Daemon)

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
- `WORDPRESS_BASE_URL`, `WORDPRESS_USERNAME`, `WORDPRESS_APP_PASSWORD` (wordpress mode)
- `WORKER_PUBLISH_DEFAULT_TAGS` (comma-separated)

## Endpoints (initial)
- `GET /health`
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
