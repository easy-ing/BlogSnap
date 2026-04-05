# Backend (Day 4 Worker Scaffold)

## Run
```bash
uvicorn backend.app.main:app --reload --port 8000
```

## Required env
- `DATABASE_URL` (default: `postgresql+psycopg://blogsnap:blogsnap@localhost:55432/blogsnap`)

## Endpoints (initial)
- `GET /health`
- `POST /v1/drafts/generate`
- `GET /v1/drafts?project_id=...`
- `POST /v1/drafts/{draft_id}/regenerate`
- `POST /v1/publish`
- `GET /v1/jobs/{job_id}`
- `POST /v1/jobs/{job_id}/run`
- `POST /v1/jobs/run-next`

## Worker
Run next pending/retrying job once:
```bash
PYTHONPATH=. python3 -m backend.app.worker.run_once
```

Day4 demo:
```bash
./scripts/db_reset.sh
./scripts/day4_run_demo.sh
```
