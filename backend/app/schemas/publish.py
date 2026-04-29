from uuid import UUID
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from backend.app.models.enums import ProviderType, PublishStatus, ScheduleStatus


class PublishRequest(BaseModel):
    project_id: UUID
    draft_id: UUID
    provider: ProviderType = ProviderType.wordpress
    idempotency_key: Optional[str] = None
    publish_at: Optional[datetime] = None


class PublishResponse(BaseModel):
    id: UUID
    project_id: UUID
    draft_id: UUID
    status: PublishStatus
    post_url: Optional[str]
    schedule_status: ScheduleStatus
    scheduled_at: Optional[datetime]
    cancelled_at: Optional[datetime]
    error_message: Optional[str]
    request_snapshot: dict

    model_config = ConfigDict(from_attributes=True)


class PublishScheduleUpdateRequest(BaseModel):
    publish_at: Optional[datetime] = Field(
        default=None,
        description="예약 시간. null이면 즉시 실행 가능 상태로 전환",
    )
