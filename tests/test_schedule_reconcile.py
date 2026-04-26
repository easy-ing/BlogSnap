from datetime import datetime, timedelta, timezone
import uuid

from sqlalchemy import select

from backend.app.models.entities import Job, PublishJob
from backend.app.models.enums import JobStatus, ScheduleStatus


def _auth_headers(client, prefix: str) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"{prefix}-{uuid.uuid4()}@blogsnap.local", "display_name": prefix},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _seed_selected_draft(client, headers: dict[str, str]) -> tuple[str, str]:
    project_resp = client.post("/v1/projects", json={"name": "Reconcile Project"}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]

    generate_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": project_id,
            "post_type": "explanation",
            "keyword": "reconcile",
            "sentiment": 1,
            "draft_count": 2,
        },
        headers=headers,
    )
    assert generate_resp.status_code == 200
    generate_job_id = generate_resp.json()["id"]
    run_generate = client.post(f"/v1/jobs/{generate_job_id}/run", headers=headers)
    assert run_generate.status_code == 200

    drafts_resp = client.get("/v1/drafts", params={"project_id": project_id}, headers=headers)
    draft_id = drafts_resp.json()[0]["id"]
    client.post(f"/v1/drafts/{draft_id}/select", headers=headers)
    return project_id, draft_id


def test_reconcile_activates_due_scheduled_publish(client, db) -> None:
    headers = _auth_headers(client, "reconcile-due")
    project_id, draft_id = _seed_selected_draft(client, headers)

    future = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()
    create_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "wordpress",
            "publish_at": future,
            "idempotency_key": f"reconcile-due-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert create_resp.status_code == 200
    job_id = create_resp.json()["id"]

    publish_job = db.scalar(select(PublishJob).where(PublishJob.job_id == job_id))
    assert publish_job is not None
    job = db.get(Job, job_id)
    assert job is not None

    # Force due state before reconciler runs.
    past = datetime.now(timezone.utc) - timedelta(minutes=1)
    publish_job.scheduled_at = past
    publish_job.schedule_status = ScheduleStatus.SCHEDULED
    job.status = JobStatus.RETRYING
    job.next_retry_at = past
    db.commit()

    reconcile_resp = client.post("/v1/jobs/reconcile-schedules", params={"project_id": project_id}, headers=headers)
    assert reconcile_resp.status_code == 200
    payload = reconcile_resp.json()
    assert payload["activated"] >= 1

    db.refresh(publish_job)
    db.refresh(job)
    assert publish_job.schedule_status == ScheduleStatus.READY
    assert job.status == JobStatus.PENDING
    assert job.next_retry_at is None

    run_resp = client.post(f"/v1/jobs/{job_id}/run", headers=headers)
    assert run_resp.status_code == 200
    assert run_resp.json()["status"] == "SUCCEEDED"


def test_reconcile_keeps_future_schedule_waiting(client, db) -> None:
    headers = _auth_headers(client, "reconcile-wait")
    project_id, draft_id = _seed_selected_draft(client, headers)

    future_time = datetime.now(timezone.utc) + timedelta(minutes=15)
    create_resp = client.post(
        "/v1/publish",
        json={
            "project_id": project_id,
            "draft_id": draft_id,
            "provider": "wordpress",
            "publish_at": future_time.isoformat(),
            "idempotency_key": f"reconcile-wait-{uuid.uuid4()}",
        },
        headers=headers,
    )
    assert create_resp.status_code == 200
    job_id = create_resp.json()["id"]

    publish_job = db.scalar(select(PublishJob).where(PublishJob.job_id == job_id))
    assert publish_job is not None
    job = db.get(Job, job_id)
    assert job is not None

    reconcile_resp = client.post("/v1/jobs/reconcile-schedules", params={"project_id": project_id}, headers=headers)
    assert reconcile_resp.status_code == 200
    payload = reconcile_resp.json()
    assert payload["waiting"] >= 1

    db.refresh(publish_job)
    db.refresh(job)
    assert publish_job.schedule_status == ScheduleStatus.SCHEDULED
    assert job.status == JobStatus.RETRYING
    assert job.next_retry_at is not None


def test_reconcile_requires_project_owner(client, db) -> None:
    owner_headers = _auth_headers(client, "reconcile-owner")
    other_headers = _auth_headers(client, "reconcile-other")
    project_id, _ = _seed_selected_draft(client, owner_headers)

    deny_resp = client.post("/v1/jobs/reconcile-schedules", params={"project_id": project_id}, headers=other_headers)
    assert deny_resp.status_code == 403
