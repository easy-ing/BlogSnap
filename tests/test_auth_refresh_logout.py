import uuid


def _login(client, prefix: str) -> dict:
    resp = client.post(
        "/v1/auth/login",
        json={"email": f"{prefix}-{uuid.uuid4()}@blogsnap.local", "display_name": prefix},
    )
    assert resp.status_code == 200
    return resp.json()


def test_refresh_rotates_refresh_token_and_keeps_access_valid(client, db) -> None:
    login_payload = _login(client, "refresh")
    access_token = login_payload["access_token"]
    refresh_token = login_payload["refresh_token"]

    me_resp = client.get("/v1/auth/me", headers={"Authorization": f"Bearer {access_token}"})
    assert me_resp.status_code == 200

    refresh_resp = client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_resp.status_code == 200
    refreshed = refresh_resp.json()
    assert refreshed["access_token"] != access_token
    assert refreshed["refresh_token"] != refresh_token


def test_logout_revokes_refresh_token(client, db) -> None:
    login_payload = _login(client, "logout")
    refresh_token = login_payload["refresh_token"]

    logout_resp = client.post("/v1/auth/logout", json={"refresh_token": refresh_token})
    assert logout_resp.status_code == 200
    assert logout_resp.json()["status"] == "ok"

    refresh_after_logout = client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_after_logout.status_code == 401
