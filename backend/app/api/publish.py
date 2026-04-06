from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.models.entities import Draft, Job, Project, PublishJob
from backend.app.models.enums import JobStatus, JobType, PublishStatus
from backend.app.schemas.jobs import JobResponse
from backend.app.schemas.publish import PublishRequest, PublishResponse


router = APIRouter(prefix="/v1/publish", tags=["publish"])


@router.post("", response_model=JobResponse)
def create_publish_job(payload: PublishRequest, db: Session = Depends(get_db)) -> Job:
    project = db.get(Project, payload.project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    draft = db.get(Draft, payload.draft_id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")

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

    job = Job(
        project_id=payload.project_id,
        type=JobType.publish,
        status=JobStatus.PENDING,
        idempotency_key=payload.idempotency_key,
        request_payload=payload.model_dump(mode="json"),
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
def get_publish_job(publish_job_id: UUID, db: Session = Depends(get_db)) -> PublishJob:
    publish_job = db.get(PublishJob, publish_job_id)
    if not publish_job:
        raise HTTPException(status_code=404, detail="Publish job not found")
    return publish_job
