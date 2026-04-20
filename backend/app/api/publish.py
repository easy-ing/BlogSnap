from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import ensure_project_owner, get_current_user
from backend.app.db.session import get_db
from backend.app.models.entities import Draft, Job, PublishJob, User
from backend.app.models.enums import JobStatus, JobType, PublishStatus
from backend.app.schemas.jobs import JobResponse
from backend.app.schemas.publish import PublishRequest, PublishResponse


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
    if publish_at and publish_at > now:
        initial_status = JobStatus.RETRYING
        next_retry_at = publish_at

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
    )
    db.add(pub)

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
