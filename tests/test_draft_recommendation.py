import uuid


def _auth_headers(client, prefix: str) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"{prefix}-{uuid.uuid4()}@blogsnap.local", "display_name": prefix},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _seed_project_with_drafts(client, headers: dict[str, str]) -> tuple[str, str]:
    project_resp = client.post("/v1/projects", json={"name": "Recommendation Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    generate_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": project_id,
            "post_type": "review",
            "keyword": "Day20 추천",
            "sentiment": 1,
            "draft_count": 3,
            "idempotency_key": f"day20-gen-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert generate_resp.status_code == 200
    generate_job_id = generate_resp.json()["id"]

    run_resp = client.post(f"/v1/jobs/{generate_job_id}/run", headers=headers)
    assert run_resp.status_code == 200
    assert run_resp.json()["status"] == "SUCCEEDED"
    return project_id, generate_job_id


def test_recommend_returns_ranked_candidates(client, db) -> None:
    headers = _auth_headers(client, "recommend")
    project_id, _ = _seed_project_with_drafts(client, headers)

    recommend_resp = client.get("/v1/drafts/recommend", params={"project_id": project_id}, headers=headers)
    assert recommend_resp.status_code == 200

    payload = recommend_resp.json()
    assert payload["project_id"] == project_id
    assert payload["latest_version_no"] == 1
    assert payload["recommended_draft_id"]
    assert payload["recommended_title"]
    assert payload["recommendation_reason"]

    candidates = payload["candidates"]
    assert len(candidates) == 3
    assert all("quality_score" in item for item in candidates)
    assert all("score_reasons" in item and item["score_reasons"] for item in candidates)
    assert candidates[0]["quality_score"] >= candidates[-1]["quality_score"]
    assert any(item["id"] == payload["recommended_draft_id"] for item in candidates)


def test_recommend_requires_project_ownership(client, db) -> None:
    owner_headers = _auth_headers(client, "owner")
    other_headers = _auth_headers(client, "other")
    project_id, _ = _seed_project_with_drafts(client, owner_headers)

    deny_resp = client.get("/v1/drafts/recommend", params={"project_id": project_id}, headers=other_headers)
    assert deny_resp.status_code == 403
