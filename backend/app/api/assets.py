import mimetypes
from datetime import datetime, timezone
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import ensure_project_owner, get_current_user
from backend.app.db.session import get_db
from backend.app.models.entities import Asset, User
from backend.app.models.enums import AssetStatus
from backend.app.schemas.assets import AssetItemResponse


router = APIRouter(prefix="/v1/assets", tags=["assets"])


UPLOAD_ROOT = Path("tmp/uploads")
UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)


@router.post("/upload", response_model=AssetItemResponse)
async def upload_asset(
    project_id: UUID = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Asset:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Empty file")

    guessed_content_type = file.content_type or mimetypes.guess_type(file.filename or "")[0] or "application/octet-stream"
    now = datetime.now(timezone.utc)
    storage_key = f"{project_id}/{now.strftime('%Y%m%d')}/{uuid4()}-{file.filename or 'upload.bin'}"

    output_path = UPLOAD_ROOT / storage_key
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(content)

    asset = Asset(
        project_id=project_id,
        storage_key=storage_key,
        source_filename=file.filename,
        content_type=guessed_content_type,
        byte_size=len(content),
        url=f"/tmp/uploads/{storage_key}",
        status=AssetStatus.AVAILABLE,
    )
    db.add(asset)
    db.commit()
    db.refresh(asset)
    return asset


@router.get("", response_model=list[AssetItemResponse])
def list_assets(
    project_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Asset]:
    ensure_project_owner(db=db, project_id=project_id, user_id=current_user.id)
    stmt = select(Asset).where(Asset.project_id == project_id).order_by(Asset.created_at.desc())
    return list(db.scalars(stmt))
