from datetime import datetime, timedelta, timezone
import uuid

from sqlalchemy import select

from backend.app.models.entities import PublishJob


def _auth_headers(client, prefix: str) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"{prefix}-{uuid.uuid4()}@blogsnap.local", "display_name": prefix},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _prepare_selected_draft(client, headers: dict[str, str]) -> tuple[str, str]:
    project_resp = client.post("/v1/projects", json={"name": "Schedule Controls Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    generate_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": project_id,
            "post_type": "explanation",
            "keyword": "예약 제어",
            "sentiment": 1,
            "draft_count": 2,
        },
        headers=headers,
    )
    assert generate_resp.status_code == 200
    generate_job_id = generate_resp.json()["id"]
    run_generate = client.post(f"/v1/jobs/{generate_job_id}/run", headers=headers)
    assert run_generate.status_code == 200
    assert run_generate.json()["status"] == "SUCCEEDED"

    drafts_resp = client.get("/v1/drafts", params={"project_id": project_id}, headers=headers)
    assert drafts_resp.status_code == 200
    draft_id = drafts_resp.json()[0]["id"]
    select_resp = client.post(f"/v1/drafts/{draft_id}/select", headers=headers)
    assert select_resp.status_code == 200
    return project_id, draft_id


def test_schedule_update_changes_run_gate(client, db) -> None:
    headers = _auth_headers(client, "schedule-update")
    project_id, draft_id = _prepare_selected_draft(client, headers)
    future_publish_at = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()

    publish_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "wordpress",
            "publish_at": future_publish_at,
            "idempotency_key": f"schedule-update-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert publish_resp.status_code == 200
    job_id = publish_resp.json()["id"]

    publish_job = db.scalar(select(PublishJob).where(PublishJob.job_id == job_id))
    assert publish_job is not None

    # Before schedule update, job should remain RETRYING.
    run_early = client.post(f"/v1/jobs/{job_id}/run", headers=headers)
    assert run_early.status_code == 200
    assert run_early.json()["status"] == "RETRYING"

    patch_resp = client.patch(
        f"/v1/publish/{publish_job.id}/schedule",
        json={"publish_at": None},
        headers=headers,
    )
    assert patch_resp.status_code == 200
    patch_payload = patch_resp.json()
    assert patch_payload["schedule_status"] == "READY"
    assert patch_payload["scheduled_at"] is None

    run_now = client.post(f"/v1/jobs/{job_id}/run", headers=headers)
    assert run_now.status_code == 200
    assert run_now.json()["status"] == "SUCCEEDED"


def test_cancel_scheduled_publish_blocks_execution(client, db) -> None:
    headers = _auth_headers(client, "schedule-cancel")
    project_id, draft_id = _prepare_selected_draft(client, headers)
    future_publish_at = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()

    publish_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "wordpress",
            "publish_at": future_publish_at,
            "idempotency_key": f"schedule-cancel-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert publish_resp.status_code == 200
    job_id = publish_resp.json()["id"]

    publish_job = db.scalar(select(PublishJob).where(PublishJob.job_id == job_id))
    assert publish_job is not None

    cancel_resp = client.post(f"/v1/publish/{publish_job.id}/cancel", headers=headers)
    assert cancel_resp.status_code == 200
    cancel_payload = cancel_resp.json()
    assert cancel_payload["schedule_status"] == "CANCELLED"
    assert cancel_payload["status"] == "ERROR"
    assert cancel_payload["cancelled_at"] is not None

    run_after_cancel = client.post(f"/v1/jobs/{job_id}/run", headers=headers)
    assert run_after_cancel.status_code == 200
    run_payload = run_after_cancel.json()
    assert run_payload["status"] == "FAILED"
    assert "cancelled" in (run_payload.get("error_message") or "").lower()


def test_schedule_controls_require_project_ownership(client, db) -> None:
    owner_headers = _auth_headers(client, "schedule-owner")
    other_headers = _auth_headers(client, "schedule-other")
    project_id, draft_id = _prepare_selected_draft(client, owner_headers)

    publish_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "wordpress",
            "idempotency_key": f"schedule-owner-pub-{uuid.uuid4()}",
        },
        headers=owner_headers,
    )
    assert publish_resp.status_code == 200
    job_id = publish_resp.json()["id"]
    run_resp = client.post(f"/v1/jobs/{job_id}/run", headers=owner_headers)
    assert run_resp.status_code == 200

    publish_job = db.scalar(select(PublishJob).where(PublishJob.job_id == job_id))
    assert publish_job is not None

    deny_patch = client.patch(
        f"/v1/publish/{publish_job.id}/schedule",
        json={"publish_at": (datetime.now(timezone.utc) + timedelta(minutes=5)).isoformat()},
        headers=other_headers,
    )
    assert deny_patch.status_code == 403

    deny_cancel = client.post(f"/v1/publish/{publish_job.id}/cancel", headers=other_headers)
    assert deny_cancel.status_code == 403
