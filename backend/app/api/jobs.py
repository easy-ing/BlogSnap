from collections import Counter
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from backend.app.core.auth import ensure_project_owner, get_current_user
from backend.app.db.session import get_db
from backend.app.models.entities import Job, User
from backend.app.models.enums import JobStatus
from backend.app.schemas.jobs import JobResponse, QueueSummaryResponse, ScheduleReconcileResponse
from backend.app.worker.runner import JobRunner
from backend.app.worker.scheduler import reconcile_scheduled_publish_jobs


router = APIRouter(prefix="/v1/jobs", tags=["jobs"])


@router.post("/run-batch", response_model=list[JobResponse])
def run_batch_jobs(
    project_id: UUID = Query(...),
    limit: int = Query(default=10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Job]:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)
    runner = JobRunner(db)
    processed: list[Job] = []
    now = datetime.now(timezone.utc)
    for _ in range(limit):
        job = db.scalar(
            select(Job)
            .where(
                Job.project_id == project_id,
                Job.status.in_([JobStatus.PENDING, JobStatus.RETRYING]),
                or_(Job.next_retry_at.is_(None), Job.next_retry_at <= now),
            )
            .order_by(Job.created_at.asc())
            .limit(1)
        )
        if not job:
            break
        processed.append(runner.run_job_by_id(job.id))
    return processed


@router.get("/queue-summary", response_model=QueueSummaryResponse)
def queue_summary(
    project_id: UUID = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> QueueSummaryResponse:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)
    statuses = list(db.scalars(select(Job.status).where(Job.project_id == project_id)))
    counts = Counter(statuses)
    return QueueSummaryResponse(
        pending=counts.get(JobStatus.PENDING, 0),
        retrying=counts.get(JobStatus.RETRYING, 0),
        running=counts.get(JobStatus.RUNNING, 0),
        failed=counts.get(JobStatus.FAILED, 0),
        succeeded=counts.get(JobStatus.SUCCEEDED, 0),
    )


@router.post("/run-next", response_model=JobResponse)
def run_next_job(
    project_id: UUID = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Job:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)
    now = datetime.now(timezone.utc)
    job = db.scalar(
        select(Job)
        .where(
            Job.project_id == project_id,
            Job.status.in_([JobStatus.PENDING, JobStatus.RETRYING]),
            or_(Job.next_retry_at.is_(None), Job.next_retry_at <= now),
        )
        .order_by(Job.created_at.asc())
        .limit(1)
    )
    if not job:
        raise HTTPException(status_code=404, detail="No runnable jobs")
    runner = JobRunner(db)
    return runner.run_job_by_id(job.id)


@router.post("/reconcile-schedules", response_model=ScheduleReconcileResponse)
def reconcile_schedules(
    project_id: UUID = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ScheduleReconcileResponse:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)
    payload = reconcile_scheduled_publish_jobs(db=db, project_id=project_id)
    return ScheduleReconcileResponse(**payload)


@router.post("/{job_id}/run", response_model=JobResponse)
def run_job(
    job_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Job:
    job = db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    ensure_project_owner(db=db, project_id=job.project_id, user_id=current_user.id)
    runner = JobRunner(db)
    return runner.run_job_by_id(job_id)


@router.get("/{job_id}", response_model=JobResponse)
def get_job(
    job_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Job:
    job = db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    ensure_project_owner(db=db, project_id=job.project_id, user_id=current_user.id)
    return job
