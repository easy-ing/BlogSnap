from uuid import UUID
from typing import Optional

from pydantic import BaseModel

from backend.app.models.enums import ProviderType, PublishStatus


class PublishRequest(BaseModel):
    project_id: UUID
    draft_id: UUID
    provider: ProviderType = ProviderType.wordpress
    idempotency_key: Optional[str] = None


class PublishResponse(BaseModel):
    id: UUID
    project_id: UUID
    draft_id: UUID
    status: PublishStatus
    post_url: Optional[str]

    class Config:
        from_attributes = True
