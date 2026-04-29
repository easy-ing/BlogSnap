from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ProjectCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)


class ProjectItemResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str

    model_config = ConfigDict(from_attributes=True)
