import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from backend.app.models.entities import Asset, Project, User
from backend.app.models.enums import AssetStatus, ProviderType
from backend.app.services.asset_cleanup import purge_deleted_assets_all_projects


def test_purge_deleted_assets_all_projects(db) -> None:
    user = User(email=f"svc-{uuid.uuid4()}@blogsnap.local", display_name="svc")
    db.add(user)
    db.flush()

    project1 = Project(user_id=user.id, name="P1", default_provider=ProviderType.wordpress)
    project2 = Project(user_id=user.id, name="P2", default_provider=ProviderType.wordpress)
    db.add(project1)
    db.add(project2)
    db.flush()

    old_time = datetime.now(timezone.utc) - timedelta(hours=72)

    a1 = Asset(
        project_id=project1.id,
        storage_key=f"{project1.id}/old1.png",
        source_filename="old1.png",
        content_type="image/png",
        byte_size=10,
        status=AssetStatus.DELETED,
        updated_at=old_time,
    )
    a2 = Asset(
        project_id=project2.id,
        storage_key=f"{project2.id}/old2.png",
        source_filename="old2.png",
        content_type="image/png",
        byte_size=12,
        status=AssetStatus.DELETED,
        updated_at=old_time,
    )
    keep = Asset(
        project_id=project2.id,
        storage_key=f"{project2.id}/keep.png",
        source_filename="keep.png",
        content_type="image/png",
        byte_size=14,
        status=AssetStatus.AVAILABLE,
    )
    db.add_all([a1, a2, keep])
    db.commit()

    result = purge_deleted_assets_all_projects(db, retention_hours=24)
    assert result["projects"] >= 2
    assert result["purged"] == 2

    remaining = list(db.scalars(select(Asset).order_by(Asset.created_at.asc())))
    assert len(remaining) == 1
    assert remaining[0].status == AssetStatus.AVAILABLE
