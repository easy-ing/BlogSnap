from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import get_current_user
from backend.app.db.session import get_db
from backend.app.models.entities import Project, User
from backend.app.schemas.projects import ProjectCreateRequest, ProjectItemResponse


router = APIRouter(prefix="/v1/projects", tags=["projects"])


@router.post("", response_model=ProjectItemResponse)
def create_project(
    payload: ProjectCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Project:
    project = Project(user_id=current_user.id, name=payload.name.strip())
    db.add(project)
    db.commit()
    db.refresh(project)
    return project


@router.get("", response_model=list[ProjectItemResponse])
def list_projects(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Project]:
    stmt = select(Project).where(Project.user_id == current_user.id).order_by(Project.created_at.desc())
    return list(db.scalars(stmt))
