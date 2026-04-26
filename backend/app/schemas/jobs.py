from datetime import datetime
from uuid import UUID
from typing import Optional

from pydantic import BaseModel

from backend.app.models.enums import JobStatus, JobType


class JobResponse(BaseModel):
    id: UUID
    project_id: UUID
    type: JobType
    status: JobStatus
    attempt_count: int
    max_attempts: int
    error_message: Optional[str]
    result_payload: dict
    next_retry_at: Optional[datetime]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class QueueSummaryResponse(BaseModel):
    pending: int
    retrying: int
    running: int
    failed: int
    succeeded: int


class ScheduleReconcileResponse(BaseModel):
    project_id: Optional[UUID]
    scanned: int
    activated: int
    waiting: int
