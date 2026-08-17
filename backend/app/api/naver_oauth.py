import secrets
from datetime import datetime, timedelta, timezone
from urllib.parse import urlencode

import requests
from fastapi import APIRouter, Depends, Query
from fastapi.responses import RedirectResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.core.auth import get_current_user
from backend.app.core.config import settings
from backend.app.db.session import get_db
from backend.app.models.entities import OAuthState, ProviderToken, User
from backend.app.models.enums import ProviderType
from backend.app.services.secret_crypto import encrypt_secret


router = APIRouter(prefix="/v1/auth/naver", tags=["naver-oauth"])

STATE_TTL_MINUTES = 10
NAVER_AUTHORIZE_URL = "https://nid.naver.com/oauth2.0/authorize"
NAVER_TOKEN_URL = "https://nid.naver.com/oauth2.0/token"


@router.get("/login-url")
def get_naver_login_url(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    state = secrets.token_urlsafe(24)
    oauth_state = OAuthState(
        user_id=current_user.id,
        provider=ProviderType.naver,
        state=state,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=STATE_TTL_MINUTES),
    )
    db.add(oauth_state)
    db.commit()

    params = {
        "response_type": "code",
        "client_id": settings.naver_client_id,
        "redirect_uri": settings.naver_redirect_uri,
        "state": state,
    }
    return {"login_url": f"{NAVER_AUTHORIZE_URL}?{urlencode(params)}"}


@router.get("/callback")
def naver_callback(
    code: str | None = Query(default=None),
    state: str | None = Query(default=None),
    error: str | None = Query(default=None),
    db: Session = Depends(get_db),
) -> RedirectResponse:
    if error or not code or not state:
        return RedirectResponse(settings.naver_login_failure_redirect)

    oauth_state = db.scalar(select(OAuthState).where(OAuthState.state == state))
    now = datetime.now(timezone.utc)
    if not oauth_state or oauth_state.expires_at <= now:
        return RedirectResponse(settings.naver_login_failure_redirect)

    try:
        token_resp = requests.post(
            NAVER_TOKEN_URL,
            data={
                "grant_type": "authorization_code",
                "client_id": settings.naver_client_id,
                "client_secret": settings.naver_client_secret,
                "code": code,
                "state": state,
                "redirect_uri": settings.naver_redirect_uri,
            },
            timeout=20,
        )
        token_resp.raise_for_status()
        token_data = token_resp.json()
        access_token = token_data["access_token"]
        refresh_token = token_data.get("refresh_token")
        expires_in = token_data.get("expires_in")
    except Exception:
        db.delete(oauth_state)
        db.commit()
        return RedirectResponse(settings.naver_login_failure_redirect)

    existing = db.scalar(
        select(ProviderToken).where(
            ProviderToken.user_id == oauth_state.user_id,
            ProviderToken.provider == ProviderType.naver,
        )
    )
    token_expires_at = now + timedelta(seconds=int(expires_in)) if expires_in else None
    if existing:
        existing.encrypted_access_token = encrypt_secret(access_token)
        existing.encrypted_refresh_token = encrypt_secret(refresh_token) if refresh_token else None
        existing.token_expires_at = token_expires_at
        existing.updated_at = now
    else:
        db.add(
            ProviderToken(
                user_id=oauth_state.user_id,
                provider=ProviderType.naver,
                encrypted_access_token=encrypt_secret(access_token),
                encrypted_refresh_token=encrypt_secret(refresh_token) if refresh_token else None,
                token_expires_at=token_expires_at,
            )
        )

    db.delete(oauth_state)
    db.commit()
    return RedirectResponse(settings.naver_login_success_redirect)


@router.delete("")
def disconnect_naver(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    existing = db.scalar(
        select(ProviderToken).where(
            ProviderToken.user_id == current_user.id,
            ProviderToken.provider == ProviderType.naver,
        )
    )
    if existing:
        db.delete(existing)
        db.commit()
    return {"naver_connected": False}
