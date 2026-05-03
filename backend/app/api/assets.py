import mimetypes
from datetime import datetime, timezone
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import ensure_project_owner, get_current_user
from backend.app.core.config import settings
from backend.app.db.session import get_db
from backend.app.models.entities import Asset, User
from backend.app.models.enums import AssetStatus
from backend.app.schemas.assets import AssetItemResponse


router = APIRouter(prefix="/v1/assets", tags=["assets"])


UPLOAD_ROOT = Path("tmp/uploads")
UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)


def _allowed_types() -> set[str]:
    return {item.strip() for item in settings.asset_allowed_content_types.split(",") if item.strip()}


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
    if guessed_content_type not in _allowed_types():
        raise HTTPException(status_code=400, detail=f"Unsupported content type: {guessed_content_type}")
    if len(content) > settings.asset_max_bytes:
        raise HTTPException(status_code=400, detail=f"File too large (max {settings.asset_max_bytes} bytes)")

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
    stmt = (
        select(Asset)
        .where(Asset.project_id == project_id, Asset.status != AssetStatus.DELETED)
        .order_by(Asset.created_at.desc())
    )
    return list(db.scalars(stmt))


@router.delete("/{asset_id}", response_model=AssetItemResponse)
def delete_asset(
    asset_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Asset:
    asset = db.get(Asset, asset_id)
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    ensure_project_owner(db=db, project_id=asset.project_id, user_id=current_user.id)

    if asset.status == AssetStatus.DELETED:
        return asset

    file_path = UPLOAD_ROOT / asset.storage_key
    if file_path.exists():
        file_path.unlink()

    asset.status = AssetStatus.DELETED
    asset.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(asset)
    return asset
