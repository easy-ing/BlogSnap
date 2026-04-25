from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import ensure_project_owner, get_current_user
from backend.app.db.session import get_db
from backend.app.models.entities import Draft, Job, PublishJob, User
from backend.app.models.enums import JobStatus, JobType, PublishStatus, ScheduleStatus
from backend.app.schemas.jobs import JobResponse
from backend.app.schemas.publish import PublishRequest, PublishResponse, PublishScheduleUpdateRequest


router = APIRouter(prefix="/v1/publish", tags=["publish"])


def _normalize_publish_at(value: Optional[datetime]) -> Optional[datetime]:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


@router.post("", response_model=JobResponse)
def create_publish_job(
    payload: PublishRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Job:
    ensure_project_owner(db=db, project_id=payload.project_id, user_id=current_user.id)

    draft = db.get(Draft, payload.draft_id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    if draft.project_id != payload.project_id:
        raise HTTPException(status_code=400, detail="Draft and project mismatch")

    if payload.idempotency_key:
        existing = db.scalar(
            select(Job).where(
                Job.project_id == payload.project_id,
                Job.type == JobType.publish,
                Job.idempotency_key == payload.idempotency_key,
            )
        )
        if existing:
            return existing

    publish_at = _normalize_publish_at(payload.publish_at)
    now = datetime.now(timezone.utc)
    initial_status = JobStatus.PENDING
    next_retry_at = None
    schedule_status = ScheduleStatus.READY
    if publish_at and publish_at > now:
        initial_status = JobStatus.RETRYING
        next_retry_at = publish_at
        schedule_status = ScheduleStatus.SCHEDULED

    job = Job(
        project_id=payload.project_id,
        type=JobType.publish,
        status=initial_status,
        idempotency_key=payload.idempotency_key,
        request_payload=payload.model_dump(mode="json"),
        next_retry_at=next_retry_at,
    )
    db.add(job)
    db.flush()

    pub = PublishJob(
        project_id=payload.project_id,
        draft_id=payload.draft_id,
        job_id=job.id,
        provider=payload.provider,
        status=PublishStatus.REQUESTED,
        request_snapshot=payload.model_dump(mode="json"),
        schedule_status=schedule_status,
        scheduled_at=publish_at,
    )
    db.add(pub)
    db.flush()
    job.result_payload = {"publish_job_id": str(pub.id)}

    db.commit()
    db.refresh(job)
    return job


@router.get("/{publish_job_id}", response_model=PublishResponse)
def get_publish_job(
    publish_job_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PublishJob:
    publish_job = db.get(PublishJob, publish_job_id)
    if not publish_job:
        raise HTTPException(status_code=404, detail="Publish job not found")
    ensure_project_owner(db=db, project_id=publish_job.project_id, user_id=current_user.id)
    return publish_job


@router.patch("/{publish_job_id}/schedule", response_model=PublishResponse)
def update_publish_schedule(
    publish_job_id: UUID,
    payload: PublishScheduleUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PublishJob:
    publish_job = db.get(PublishJob, publish_job_id)
    if not publish_job:
        raise HTTPException(status_code=404, detail="Publish job not found")
    ensure_project_owner(db=db, project_id=publish_job.project_id, user_id=current_user.id)

    if publish_job.status == PublishStatus.PUBLISHED:
        raise HTTPException(status_code=400, detail="Already published")
    if publish_job.schedule_status == ScheduleStatus.CANCELLED:
        raise HTTPException(status_code=400, detail="Cancelled publish job cannot be rescheduled")
    if not publish_job.job_id:
        raise HTTPException(status_code=400, detail="Publish job is not linked to execution job")

    job = db.get(Job, publish_job.job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Execution job not found")
    if job.status == JobStatus.SUCCEEDED:
        raise HTTPException(status_code=400, detail="Execution job already succeeded")

    publish_at = _normalize_publish_at(payload.publish_at)
    now = datetime.now(timezone.utc)
    if publish_at and publish_at > now:
        publish_job.schedule_status = ScheduleStatus.SCHEDULED
        publish_job.scheduled_at = publish_at
        job.status = JobStatus.RETRYING
        job.next_retry_at = publish_at
        job.completed_at = None
    else:
        publish_job.schedule_status = ScheduleStatus.READY
        publish_job.scheduled_at = publish_at
        job.status = JobStatus.PENDING
        job.next_retry_at = None
        job.completed_at = None

    request_snapshot = dict(publish_job.request_snapshot or {})
    request_snapshot["publish_at"] = publish_at.isoformat() if publish_at else None
    publish_job.request_snapshot = request_snapshot
    publish_job.updated_at = now
    job.request_payload = request_snapshot
    job.error_message = None
    job.updated_at = now

    db.commit()
    db.refresh(publish_job)
    return publish_job


@router.post("/{publish_job_id}/cancel", response_model=PublishResponse)
def cancel_publish_schedule(
    publish_job_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PublishJob:
    publish_job = db.get(PublishJob, publish_job_id)
    if not publish_job:
        raise HTTPException(status_code=404, detail="Publish job not found")
    ensure_project_owner(db=db, project_id=publish_job.project_id, user_id=current_user.id)

    if publish_job.status == PublishStatus.PUBLISHED:
        raise HTTPException(status_code=400, detail="Already published")
    if publish_job.schedule_status == ScheduleStatus.CANCELLED:
        return publish_job

    now = datetime.now(timezone.utc)
    publish_job.schedule_status = ScheduleStatus.CANCELLED
    publish_job.cancelled_at = now
    publish_job.status = PublishStatus.ERROR
    publish_job.error_message = "Cancelled by user"
    publish_job.updated_at = now

    if publish_job.job_id:
        job = db.get(Job, publish_job.job_id)
        if job and job.status in (JobStatus.PENDING, JobStatus.RETRYING, JobStatus.RUNNING):
            job.status = JobStatus.FAILED
            job.error_message = "Publish job cancelled by user"
            job.completed_at = now
            job.next_retry_at = None
            job.updated_at = now

    db.commit()
    db.refresh(publish_job)
    return publish_job
