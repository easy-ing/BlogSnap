from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.config import settings
from backend.app.models.entities import Asset, Project
from backend.app.models.enums import AssetStatus


UPLOAD_ROOT = Path("tmp/uploads")


def purge_deleted_assets_for_project(db: Session, project_id: UUID, retention_hours: int | None = None) -> int:
    keep_hours = retention_hours if retention_hours is not None else settings.asset_deleted_retention_hours
    cutoff = datetime.now(timezone.utc) - timedelta(hours=keep_hours)

    candidates = list(
        db.scalars(
            select(Asset).where(
                Asset.project_id == project_id,
                Asset.status == AssetStatus.DELETED,
                Asset.updated_at <= cutoff,
            )
        )
    )

    purged = 0
    for asset in candidates:
        file_path = UPLOAD_ROOT / asset.storage_key
        if file_path.exists():
            file_path.unlink()
        db.delete(asset)
        purged += 1

    db.commit()
    return purged


def purge_deleted_assets_all_projects(db: Session, retention_hours: int | None = None) -> dict[str, int]:
    project_ids = list(db.scalars(select(Project.id)))
    total = 0
    scanned_projects = 0

    for project_id in project_ids:
        scanned_projects += 1
        total += purge_deleted_assets_for_project(db, project_id, retention_hours=retention_hours)

    return {"projects": scanned_projects, "purged": total}
