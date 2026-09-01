import uuid

import pytest

from backend.app.models.entities import Project, User
from backend.app.services.secret_crypto import decrypt_secret, encrypt_secret
from backend.app.worker.executor import _get_owner_gemini_key


def _login(client, prefix: str) -> dict:
    resp = client.post(
        "/v1/auth/login",
        json={"email": f"{prefix}-{uuid.uuid4()}@blogsnap.local", "display_name": prefix},
    )
    assert resp.status_code == 200
    return resp.json()


def test_secret_crypto_round_trip() -> None:
    raw = "AIzaSyExampleKeyValueForTesting1234"
    encrypted = encrypt_secret(raw)
    assert encrypted != raw
    assert decrypt_secret(encrypted) == raw


def test_me_reports_gemini_key_not_connected_by_default(client, db) -> None:
    login_payload = _login(client, "gemini-key")
    headers = {"Authorization": f"Bearer {login_payload['access_token']}"}

    me_resp = client.get("/v1/auth/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["gemini_key_connected"] is False


def test_connect_and_disconnect_gemini_key(client, db) -> None:
    login_payload = _login(client, "gemini-key")
    headers = {"Authorization": f"Bearer {login_payload['access_token']}"}

    set_resp = client.put(
        "/v1/auth/me/gemini-key",
        json={"api_key": "AIzaSyExampleKeyValueForTesting1234"},
        headers=headers,
    )
    assert set_resp.status_code == 200
    assert set_resp.json()["gemini_key_connected"] is True

    me_resp = client.get("/v1/auth/me", headers=headers)
    assert me_resp.json()["gemini_key_connected"] is True

    # the raw key must never come back through any response
    assert "AIzaSyExampleKeyValueForTesting1234" not in set_resp.text
    assert "AIzaSyExampleKeyValueForTesting1234" not in me_resp.text

    delete_resp = client.delete("/v1/auth/me/gemini-key", headers=headers)
    assert delete_resp.status_code == 200
    assert delete_resp.json()["gemini_key_connected"] is False

    me_resp_after = client.get("/v1/auth/me", headers=headers)
    assert me_resp_after.json()["gemini_key_connected"] is False


def test_get_owner_gemini_key_requires_connected_key(db) -> None:
    user = User(email=f"no-key-{uuid.uuid4()}@blogsnap.local", display_name="No Key")
    db.add(user)
    db.flush()
    project = Project(user_id=user.id, name="No Key Project")
    db.add(project)
    db.flush()

    with pytest.raises(ValueError, match="Gemini API 키"):
        _get_owner_gemini_key(db, project.id)

    user.gemini_api_key_encrypted = encrypt_secret("AIzaSyExampleKeyValueForTesting1234")
    db.flush()

    assert _get_owner_gemini_key(db, project.id) == "AIzaSyExampleKeyValueForTesting1234"
