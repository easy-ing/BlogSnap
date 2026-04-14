from __future__ import annotations

import uuid

from backend.app.models.entities import Project, User


def _seed_project(db) -> Project:
    user = User(email=f"test-{uuid.uuid4()}@blogsnap.local", display_name="Test")
    db.add(user)
    db.flush()
    project = Project(user_id=user.id, name="Integration Project")
    db.add(project)
    db.commit()
    db.refresh(project)
    return project


def test_draft_select_publish_flow(client, db) -> None:
    project = _seed_project(db)

    generate_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": str(project.id),
            "post_type": "explanation",
            "keyword": "Day13 통합 테스트",
            "sentiment": 1,
            "draft_count": 3,
            "idempotency_key": f"gen-{uuid.uuid4()}",
        },
    )
    assert generate_resp.status_code == 200
    generate_job_id = generate_resp.json()["id"]

    run_generate_resp = client.post(f"/v1/jobs/{generate_job_id}/run")
    assert run_generate_resp.status_code == 200
    run_generate_payload = run_generate_resp.json()
    assert run_generate_payload["status"] == "SUCCEEDED"
    assert len(run_generate_payload["result_payload"]["draft_ids"]) == 3

    drafts_resp = client.get("/v1/drafts", params={"project_id": str(project.id)})
    assert drafts_resp.status_code == 200
    drafts = drafts_resp.json()
    assert len(drafts) == 3
    selected_draft_id = drafts[0]["id"]

    select_resp = client.post(f"/v1/drafts/{selected_draft_id}/select")
    assert select_resp.status_code == 200
    assert select_resp.json()["status"] == "SELECTED"

    publish_key = f"pub-{uuid.uuid4()}"
    publish_resp = client.post(
        "/v1/publish",
        json={
            "project_id": str(project.id),
            "draft_id": selected_draft_id,
            "provider": "wordpress",
            "idempotency_key": publish_key,
        },
    )
    assert publish_resp.status_code == 200
    publish_job_id = publish_resp.json()["id"]

    # idempotency should return same job
    publish_resp_2 = client.post(
        "/v1/publish",
        json={
            "project_id": str(project.id),
            "draft_id": selected_draft_id,
            "provider": "wordpress",
            "idempotency_key": publish_key,
        },
    )
    assert publish_resp_2.status_code == 200
    assert publish_resp_2.json()["id"] == publish_job_id

    run_publish_resp = client.post(f"/v1/jobs/{publish_job_id}/run")
    assert run_publish_resp.status_code == 200
    run_publish_payload = run_publish_resp.json()
    assert run_publish_payload["status"] == "SUCCEEDED"
    publish_job_record_id = run_publish_payload["result_payload"]["publish_job_id"]

    publish_get_resp = client.get(f"/v1/publish/{publish_job_record_id}")
    assert publish_get_resp.status_code == 200
    publish_data = publish_get_resp.json()
    assert publish_data["status"] == "PUBLISHED"
    assert "mock-post" in (publish_data["post_url"] or "")
