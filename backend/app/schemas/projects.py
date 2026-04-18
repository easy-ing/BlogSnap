from uuid import UUID

from pydantic import BaseModel, Field


class ProjectCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)


class ProjectItemResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str

    class Config:
        from_attributes = True
