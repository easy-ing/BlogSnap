import uuid


def _auth_headers(client) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"draft-asset-{uuid.uuid4()}@blogsnap.local", "display_name": "DraftAsset Tester"},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_generate_with_deleted_asset_returns_400(client, db) -> None:
    headers = _auth_headers(client)
    project_resp = client.post("/v1/projects", json={"name": "Draft Asset Project"}, headers=headers)
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

    generate_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": project_id,
            "post_type": "review",
            "keyword": "asset validation",
            "sentiment": 1,
            "image_asset_id": asset_id,
            "draft_count": 2,
            "idempotency_key": f"gen-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert generate_resp.status_code == 400
    assert generate_resp.json()["detail"] == "Asset is not available"
