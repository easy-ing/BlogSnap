from datetime import datetime, timedelta, timezone
import uuid


def _auth_headers(client) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"schedule-{uuid.uuid4()}@blogsnap.local", "display_name": "Schedule Tester"},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_publish_job_is_scheduled_when_publish_at_is_future(client, db) -> None:
    headers = _auth_headers(client)
    project_resp = client.post("/v1/projects", json={"name": "Schedule Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    generate_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": project_id,
            "post_type": "explanation",
            "keyword": "예약 발행 테스트",
            "sentiment": 1,
            "draft_count": 2,
        },
        headers=headers,
    )
    assert generate_resp.status_code == 200
    generate_job_id = generate_resp.json()["id"]
    run_generate_resp = client.post(f"/v1/jobs/{generate_job_id}/run", headers=headers)
    assert run_generate_resp.status_code == 200

    drafts_resp = client.get("/v1/drafts", params={"project_id": project_id}, headers=headers)
    draft_id = drafts_resp.json()[0]["id"]
    client.post(f"/v1/drafts/{draft_id}/select", headers=headers)

    future_publish_at = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()
    publish_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "wordpress",
            "publish_at": future_publish_at,
            "idempotency_key": f"scheduled-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert publish_resp.status_code == 200
    publish_job = publish_resp.json()
    assert publish_job["status"] == "RETRYING"
    assert publish_job["next_retry_at"] is not None

    # Manual run should not bypass schedule gate.
    run_early_resp = client.post(f"/v1/jobs/{publish_job['id']}/run", headers=headers)
    assert run_early_resp.status_code == 200
    run_early = run_early_resp.json()
    assert run_early["status"] == "RETRYING"
    assert run_early["completed_at"] is None
