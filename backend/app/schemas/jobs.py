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
    created_at: datetime

    class Config:
        from_attributes = True
