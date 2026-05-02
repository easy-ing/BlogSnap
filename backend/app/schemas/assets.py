from uuid import UUID
from typing import Optional

from pydantic import BaseModel, ConfigDict

from backend.app.models.enums import AssetStatus


class AssetItemResponse(BaseModel):
    id: UUID
    project_id: UUID
    storage_key: str
    source_filename: Optional[str]
    content_type: str
    byte_size: int
    url: Optional[str]
    status: AssetStatus

    model_config = ConfigDict(from_attributes=True)
