from collections import Counter
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.models.entities import Job
from backend.app.models.enums import JobStatus
from backend.app.schemas.jobs import JobResponse, QueueSummaryResponse
from backend.app.worker.runner import JobRunner


router = APIRouter(prefix="/v1/jobs", tags=["jobs"])


@router.post("/run-batch", response_model=list[JobResponse])
def run_batch_jobs(
    limit: int = Query(default=10, ge=1, le=100),
    db: Session = Depends(get_db),
) -> list[Job]:
    runner = JobRunner(db)
    return runner.run_batch(limit=limit)


@router.get("/queue-summary", response_model=QueueSummaryResponse)
def queue_summary(db: Session = Depends(get_db)) -> QueueSummaryResponse:
    statuses = list(db.scalars(select(Job.status)))
    counts = Counter(statuses)
    return QueueSummaryResponse(
        pending=counts.get(JobStatus.PENDING, 0),
        retrying=counts.get(JobStatus.RETRYING, 0),
        running=counts.get(JobStatus.RUNNING, 0),
        failed=counts.get(JobStatus.FAILED, 0),
        succeeded=counts.get(JobStatus.SUCCEEDED, 0),
    )


@router.post("/run-next", response_model=JobResponse)
def run_next_job(db: Session = Depends(get_db)) -> Job:
    runner = JobRunner(db)
    job = runner.run_next()
    if not job:
        raise HTTPException(status_code=404, detail="No runnable jobs")
    return job


@router.post("/{job_id}/run", response_model=JobResponse)
def run_job(job_id: UUID, db: Session = Depends(get_db)) -> Job:
    runner = JobRunner(db)
    try:
        return runner.run_job_by_id(job_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/{job_id}", response_model=JobResponse)
def get_job(job_id: UUID, db: Session = Depends(get_db)) -> Job:
    job = db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job
