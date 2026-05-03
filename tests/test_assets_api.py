import uuid


def _auth_headers(client) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"asset-{uuid.uuid4()}@blogsnap.local", "display_name": "Asset Tester"},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_upload_asset_and_list(client, db) -> None:
    headers = _auth_headers(client)
    project_resp = client.post("/v1/projects", json={"name": "Asset Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    upload_resp = client.post(
        "/v1/assets/upload",
        headers=headers,
        files={"file": ("sample.png", b"fake-image-bytes", "image/png")},
        data={"project_id": project_id},
    )
    assert upload_resp.status_code == 200
    payload = upload_resp.json()
    assert payload["project_id"] == project_id
    assert payload["content_type"] == "image/png"
    assert payload["byte_size"] == len(b"fake-image-bytes")
    assert payload["status"] == "AVAILABLE"

    list_resp = client.get("/v1/assets", headers=headers, params={"project_id": project_id})
    assert list_resp.status_code == 200
    items = list_resp.json()
    assert len(items) == 1
    assert items[0]["id"] == payload["id"]


def test_upload_rejects_unsupported_content_type(client, db) -> None:
    headers = _auth_headers(client)
    project_resp = client.post("/v1/projects", json={"name": "Asset Validation Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    upload_resp = client.post(
        "/v1/assets/upload",
        headers=headers,
        files={"file": ("note.txt", b"hello", "text/plain")},
        data={"project_id": project_id},
    )
    assert upload_resp.status_code == 400
    assert "Unsupported content type" in upload_resp.json()["detail"]


def test_delete_asset_hides_from_list(client, db) -> None:
    headers = _auth_headers(client)
    project_resp = client.post("/v1/projects", json={"name": "Asset Delete Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    upload_resp = client.post(
        "/v1/assets/upload",
        headers=headers,
        files={"file": ("sample.png", b"fake-image-bytes", "image/png")},
        data={"project_id": project_id},
    )
    assert upload_resp.status_code == 200
    asset_id = upload_resp.json()["id"]

    delete_resp = client.delete(f"/v1/assets/{asset_id}", headers=headers)
    assert delete_resp.status_code == 200
    assert delete_resp.json()["status"] == "DELETED"

    list_resp = client.get("/v1/assets", headers=headers, params={"project_id": project_id})
    assert list_resp.status_code == 200
    assert list_resp.json() == []
