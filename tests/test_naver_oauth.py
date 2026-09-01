import uuid

import pytest
from sqlalchemy import select

from backend.app.models.entities import OAuthState, Project, ProviderToken, User
from backend.app.models.enums import ProviderType
from backend.app.services.secret_crypto import encrypt_secret
from backend.app.worker.executor import _get_owner_naver_access_token


def _login(client, prefix: str) -> tuple[dict, str]:
    email = f"{prefix}-{uuid.uuid4()}@blogsnap.local"
    resp = client.post("/v1/auth/login", json={"email": email, "display_name": prefix})
    assert resp.status_code == 200
    return resp.json(), email


def test_me_reports_naver_not_connected_by_default(client, db) -> None:
    login_payload, _ = _login(client, "naver")
    headers = {"Authorization": f"Bearer {login_payload['access_token']}"}

    me_resp = client.get("/v1/auth/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["naver_connected"] is False


def test_login_url_creates_state_and_points_at_naver(client, db) -> None:
    login_payload, _ = _login(client, "naver")
    headers = {"Authorization": f"Bearer {login_payload['access_token']}"}

    resp = client.get("/v1/auth/naver/login-url", headers=headers)
    assert resp.status_code == 200
    login_url = resp.json()["login_url"]
    assert login_url.startswith("https://nid.naver.com/oauth2.0/authorize")
    assert "state=" in login_url

    states = db.scalars(select(OAuthState)).all()
    assert len(states) == 1
    assert states[0].provider == ProviderType.naver


def test_callback_redirects_to_failure_url_on_invalid_state(client, db) -> None:
    resp = client.get(
        "/v1/auth/naver/callback",
        params={"code": "irrelevant", "state": "does-not-exist"},
        follow_redirects=False,
    )
    assert resp.status_code in (302, 307)
    assert "naver=error" in resp.headers["location"]


def test_disconnect_naver_clears_provider_token(client, db) -> None:
    login_payload, email = _login(client, "naver")
    headers = {"Authorization": f"Bearer {login_payload['access_token']}"}

    user = db.scalar(select(User).where(User.email == email))
    db.add(
        ProviderToken(
            user_id=user.id,
            provider=ProviderType.naver,
            encrypted_access_token=encrypt_secret("fake-naver-access-token"),
        )
    )
    db.commit()

    me_resp = client.get("/v1/auth/me", headers=headers)
    assert me_resp.json()["naver_connected"] is True

    delete_resp = client.delete("/v1/auth/naver", headers=headers)
    assert delete_resp.status_code == 200
    assert delete_resp.json()["naver_connected"] is False

    me_resp_after = client.get("/v1/auth/me", headers=headers)
    assert me_resp_after.json()["naver_connected"] is False


def test_get_owner_naver_access_token_requires_connected_account(db) -> None:
    user = User(email=f"no-naver-{uuid.uuid4()}@blogsnap.local", display_name="No Naver")
    db.add(user)
    db.flush()
    project = Project(user_id=user.id, name="No Naver Project")
    db.add(project)
    db.flush()

    with pytest.raises(ValueError, match="네이버 계정"):
        _get_owner_naver_access_token(db, project.id)

    db.add(
        ProviderToken(
            user_id=user.id,
            provider=ProviderType.naver,
            encrypted_access_token=encrypt_secret("fake-naver-access-token"),
        )
    )
    db.flush()

    assert _get_owner_naver_access_token(db, project.id) == "fake-naver-access-token"
