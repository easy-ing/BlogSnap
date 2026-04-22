import uuid


def _auth_headers(client) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"provider-{uuid.uuid4()}@blogsnap.local", "display_name": "Provider Tester"},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _prepare_selected_draft(client, headers: dict[str, str]) -> tuple[str, str]:
    project_resp = client.post("/v1/projects", json={"name": "Provider Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    generate_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": project_id,
            "post_type": "explanation",
            "keyword": "멀티 프로바이더 테스트",
            "sentiment": 1,
            "draft_count": 2,
        },
        headers=headers,
    )
    assert generate_resp.status_code == 200
    generate_job_id = generate_resp.json()["id"]
    run_generate_resp = client.post(f"/v1/jobs/{generate_job_id}/run", headers=headers)
    assert run_generate_resp.status_code == 200
    assert run_generate_resp.json()["status"] == "SUCCEEDED"

    drafts_resp = client.get("/v1/drafts", params={"project_id": project_id}, headers=headers)
    assert drafts_resp.status_code == 200
    draft_id = drafts_resp.json()[0]["id"]

    select_resp = client.post(f"/v1/drafts/{draft_id}/select", headers=headers)
    assert select_resp.status_code == 200
    assert select_resp.json()["status"] == "SELECTED"
    return project_id, draft_id


def test_tistory_publish_in_mock_mode_sets_provider_specific_url(client, db, monkeypatch) -> None:
    monkeypatch.setattr("backend.app.worker.executor.settings.worker_publish_mode", "mock")
    monkeypatch.setattr("backend.app.worker.executor.settings.worker_mock_publish_base_url", "https://example.com/mock-post")

    headers = _auth_headers(client)
    project_id, draft_id = _prepare_selected_draft(client, headers)

    publish_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "tistory",
            "idempotency_key": f"ti-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert publish_resp.status_code == 200
    publish_job_id = publish_resp.json()["id"]

    run_resp = client.post(f"/v1/jobs/{publish_job_id}/run", headers=headers)
    assert run_resp.status_code == 200
    run_payload = run_resp.json()
    assert run_payload["status"] == "SUCCEEDED"
    assert run_payload["result_payload"]["provider"] == "tistory"
    assert "/tistory/" in run_payload["result_payload"]["post_url"]


def test_tistory_mode_rejects_wordpress_provider(client, db, monkeypatch) -> None:
    monkeypatch.setattr("backend.app.worker.executor.settings.worker_publish_mode", "tistory")

    headers = _auth_headers(client)
    project_id, draft_id = _prepare_selected_draft(client, headers)

    publish_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "wordpress",
            "idempotency_key": f"wp-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert publish_resp.status_code == 200
    publish_job_id = publish_resp.json()["id"]

    run_resp = client.post(f"/v1/jobs/{publish_job_id}/run", headers=headers)
    assert run_resp.status_code == 200
    run_payload = run_resp.json()
    assert run_payload["status"] == "FAILED"
    assert "requires provider=tistory" in (run_payload.get("error_message") or "")
