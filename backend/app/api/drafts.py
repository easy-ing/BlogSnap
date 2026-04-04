from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.models.entities import Draft, Job, Project
from backend.app.models.enums import JobStatus, JobType
from backend.app.schemas.drafts import DraftGenerateRequest, DraftItemResponse, DraftRegenerateRequest
from backend.app.schemas.jobs import JobResponse


router = APIRouter(prefix="/v1/drafts", tags=["drafts"])


@router.post("/generate", response_model=JobResponse)
def create_draft_generation_job(payload: DraftGenerateRequest, db: Session = Depends(get_db)) -> Job:
    project = db.get(Project, payload.project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    job = Job(
        project_id=payload.project_id,
        type=JobType.draft_generate,
        status=JobStatus.PENDING,
        idempotency_key=payload.idempotency_key,
        request_payload=payload.model_dump(mode="json"),
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


@router.get("", response_model=list[DraftItemResponse])
def list_drafts(project_id: UUID, db: Session = Depends(get_db)) -> list[Draft]:
    stmt = (
        select(Draft)
        .where(Draft.project_id == project_id)
        .order_by(Draft.created_at.desc())
    )
    return list(db.scalars(stmt))


@router.post("/{draft_id}/regenerate", response_model=JobResponse)
def regenerate_draft(draft_id: UUID, payload: DraftRegenerateRequest, db: Session = Depends(get_db)) -> Job:
    draft = db.get(Draft, draft_id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")

    job = Job(
        project_id=draft.project_id,
        type=JobType.draft_regenerate,
        status=JobStatus.PENDING,
        idempotency_key=payload.idempotency_key,
        request_payload={"draft_id": str(draft_id)},
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job
