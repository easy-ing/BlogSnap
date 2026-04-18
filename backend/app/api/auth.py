from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import create_access_token, get_current_user
from backend.app.db.session import get_db
from backend.app.models.entities import User
from backend.app.schemas.auth import LoginRequest, LoginResponse, MeResponse


router = APIRouter(prefix="/v1/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    email = payload.email.strip().lower()
    user = db.scalar(select(User).where(User.email == email))
    if not user:
        user = User(email=email, display_name=payload.display_name)
        db.add(user)
        db.commit()
        db.refresh(user)
    elif payload.display_name and payload.display_name != user.display_name:
        user.display_name = payload.display_name
        db.commit()
        db.refresh(user)

    token = create_access_token(user_id=user.id)
    return LoginResponse(access_token=token)


@router.get("/me", response_model=MeResponse)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user
