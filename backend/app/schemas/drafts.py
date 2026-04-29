from uuid import UUID
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from backend.app.models.enums import DraftStatus, PostType


class DraftGenerateRequest(BaseModel):
    project_id: UUID
    post_type: PostType
    keyword: str = Field(min_length=1)
    sentiment: int = Field(ge=-2, le=2)
    image_asset_id: Optional[UUID] = None
    draft_count: int = Field(default=3, ge=2, le=3)
    idempotency_key: Optional[str] = None


class DraftRegenerateRequest(BaseModel):
    idempotency_key: Optional[str] = None


class DraftItemResponse(BaseModel):
    id: UUID
    project_id: UUID
    title: str
    keyword: str
    post_type: PostType
    sentiment: int
    version_no: int
    variant_no: int
    status: DraftStatus

    model_config = ConfigDict(from_attributes=True)


class DraftScoredItemResponse(DraftItemResponse):
    quality_score: float
    score_reasons: list[str]


class DraftRecommendationResponse(BaseModel):
    project_id: UUID
    latest_version_no: int
    recommended_draft_id: UUID
    recommended_title: str
    recommendation_reason: str
    candidates: list[DraftScoredItemResponse]
