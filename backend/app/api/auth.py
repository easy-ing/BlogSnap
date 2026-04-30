from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    get_current_user,
    hash_token,
)
from backend.app.core.config import settings
from backend.app.db.session import get_db
from backend.app.models.entities import AuthSession, User
from backend.app.schemas.auth import (
    LoginRequest,
    LoginResponse,
    LogoutRequest,
    MeResponse,
    RefreshRequest,
)


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

    access_token = create_access_token(user_id=user.id)
    refresh_token = create_refresh_token(user_id=user.id)
    refresh_expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.auth_refresh_token_exp_minutes)

    session = AuthSession(
        user_id=user.id,
        refresh_token_hash=hash_token(refresh_token),
        expires_at=refresh_expires_at,
    )
    db.add(session)
    db.commit()

    return LoginResponse(access_token=access_token, refresh_token=refresh_token)


@router.get("/me", response_model=MeResponse)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.post("/refresh", response_model=LoginResponse)
def refresh_tokens(payload: RefreshRequest, db: Session = Depends(get_db)) -> LoginResponse:
    token_payload = decode_refresh_token(payload.refresh_token)
    user_id = token_payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid refresh token subject")

    token_hash = hash_token(payload.refresh_token)
    session = db.scalar(select(AuthSession).where(AuthSession.refresh_token_hash == token_hash))
    now = datetime.now(timezone.utc)
    if not session or session.revoked_at is not None or session.expires_at <= now:
        raise HTTPException(status_code=401, detail="Refresh session invalid or expired")

    user = db.get(User, UUID(str(user_id)))
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    # rotate refresh token session
    session.revoked_at = now
    session.updated_at = now
    new_access_token = create_access_token(user_id=user.id)
    new_refresh_token = create_refresh_token(user_id=user.id)
    new_refresh_expires_at = now + timedelta(minutes=settings.auth_refresh_token_exp_minutes)
    new_session = AuthSession(
        user_id=user.id,
        refresh_token_hash=hash_token(new_refresh_token),
        expires_at=new_refresh_expires_at,
    )
    db.add(new_session)
    db.commit()
    return LoginResponse(access_token=new_access_token, refresh_token=new_refresh_token)


@router.post("/logout")
def logout(payload: LogoutRequest, db: Session = Depends(get_db)) -> dict:
    decode_refresh_token(payload.refresh_token)
    token_hash = hash_token(payload.refresh_token)
    session = db.scalar(select(AuthSession).where(AuthSession.refresh_token_hash == token_hash))
    now = datetime.now(timezone.utc)
    if session and session.revoked_at is None:
        session.revoked_at = now
        session.updated_at = now
        db.commit()
    return {"status": "ok"}
