from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import ensure_project_owner, get_current_user
from backend.app.db.session import get_db
from backend.app.models.entities import Draft, Job, User
from backend.app.models.enums import DraftStatus, JobStatus, JobType
from backend.app.schemas.drafts import (
    DraftGenerateRequest,
    DraftItemResponse,
    DraftRecommendationResponse,
    DraftRegenerateRequest,
    DraftScoredItemResponse,
)
from backend.app.schemas.jobs import JobResponse
from backend.app.services.draft_quality import rank_drafts


router = APIRouter(prefix="/v1/drafts", tags=["drafts"])


@router.post("/generate", response_model=JobResponse)
def create_draft_generation_job(
    payload: DraftGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Job:
    ensure_project_owner(db=db, project_id=payload.project_id, user_id=current_user.id)

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
def list_drafts(
    project_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Draft]:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)
    stmt = (
        select(Draft)
        .where(Draft.project_id == project_id)
        .order_by(Draft.created_at.desc())
    )
    return list(db.scalars(stmt))


@router.get("/recommend", response_model=DraftRecommendationResponse)
def recommend_draft(
    project_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DraftRecommendationResponse:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)
    drafts = list(
        db.scalars(
            select(Draft)
            .where(Draft.project_id == project_id)
            .order_by(Draft.version_no.desc(), Draft.variant_no.asc())
        )
    )
    if not drafts:
        raise HTTPException(status_code=404, detail="No drafts found")

    latest_version = max(item.version_no for item in drafts)
    latest_drafts = [item for item in drafts if item.version_no == latest_version]
    ranked = rank_drafts(latest_drafts)
    best = ranked[0]

    candidates = [
        DraftScoredItemResponse(
            id=item.draft.id,
            project_id=item.draft.project_id,
            title=item.draft.title,
            keyword=item.draft.keyword,
            post_type=item.draft.post_type,
            sentiment=item.draft.sentiment,
            version_no=item.draft.version_no,
            variant_no=item.draft.variant_no,
            status=item.draft.status,
            quality_score=item.score,
            score_reasons=item.reasons,
        )
        for item in ranked
    ]

    return DraftRecommendationResponse(
        project_id=project_id,
        latest_version_no=latest_version,
        recommended_draft_id=best.draft.id,
        recommended_title=best.draft.title,
        recommendation_reason=best.reasons[0],
        candidates=candidates,
    )


@router.post("/{draft_id}/regenerate", response_model=JobResponse)
def regenerate_draft(
    draft_id: UUID,
    payload: DraftRegenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Job:
    draft = db.get(Draft, draft_id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    ensure_project_owner(db=db, project_id=draft.project_id, user_id=current_user.id)

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


@router.post("/{draft_id}/select", response_model=DraftItemResponse)
def select_draft(
    draft_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Draft:
    draft = db.get(Draft, draft_id)
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    ensure_project_owner(db=db, project_id=draft.project_id, user_id=current_user.id)

    siblings = list(
        db.scalars(
            select(Draft).where(
                Draft.project_id == draft.project_id,
                Draft.version_no == draft.version_no,
            )
        )
    )
    for item in siblings:
        item.status = DraftStatus.SELECTED if item.id == draft.id else DraftStatus.ARCHIVED
    db.commit()
    db.refresh(draft)
    return draft
