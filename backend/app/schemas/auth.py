from uuid import UUID
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    display_name: Optional[str] = Field(default=None, max_length=120)


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class LogoutRequest(BaseModel):
    refresh_token: str = Field(min_length=20)


class MeResponse(BaseModel):
    id: UUID
    email: str
    display_name: Optional[str]
    gemini_key_connected: bool = False

    model_config = ConfigDict(from_attributes=True)


class GeminiKeySetRequest(BaseModel):
    api_key: str = Field(min_length=10, max_length=200)


class GeminiKeyStatusResponse(BaseModel):
    gemini_key_connected: bool
