from uuid import UUID
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    display_name: Optional[str] = Field(default=None, max_length=120)


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class MeResponse(BaseModel):
    id: UUID
    email: str
    display_name: Optional[str]

    model_config = ConfigDict(from_attributes=True)
