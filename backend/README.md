# Backend (Day 3 Scaffold)

## Run
```bash
uvicorn backend.app.main:app --reload --port 8000
```

## Required env
- `DATABASE_URL` (default: `postgresql+psycopg://blogsnap:blogsnap@localhost:5432/blogsnap`)

## Endpoints (initial)
- `GET /health`
- `POST /v1/drafts/generate`
- `GET /v1/drafts?project_id=...`
- `POST /v1/drafts/{draft_id}/regenerate`
- `POST /v1/publish`
- `GET /v1/jobs/{job_id}`
