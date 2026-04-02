from typing import Literal, Optional

from pydantic import BaseModel, Field


class BlogInput(BaseModel):
    keyword: str = Field(..., min_length=1)
    tone: Literal["positive", "negative", "neutral"] = "neutral"
    image_path: str
    title: Optional[str] = None
    cta: Optional[str] = None


class DraftRequest(BaseModel):
    post_type: Literal["review", "explanation", "impression"]
    keyword: str = Field(..., min_length=1)
    image_path: str
    sentiment: int = Field(default=0, ge=-2, le=2)
    cta: Optional[str] = None


class DraftItem(BaseModel):
    title: str = Field(..., min_length=1)
    markdown: str = Field(..., min_length=1)


class DraftBundle(BaseModel):
    drafts: list[DraftItem] = Field(..., min_length=2, max_length=3)
