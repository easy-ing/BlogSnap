import uuid

from backend.app.models.entities import Job
from backend.app.models.enums import JobStatus


def _auth_headers(client, prefix: str) -> dict[str, str]:
    login_resp = client.post(
        "/v1/auth/login",
        json={"email": f"{prefix}-{uuid.uuid4()}@blogsnap.local", "display_name": prefix},
    )
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _seed_generation_job(client, headers: dict[str, str], name: str) -> tuple[str, str]:
    project_resp = client.post("/v1/projects", json={"name": name}, headers=headers)
    assert project_resp.status_code == 200
    project_id = project_resp.json()["id"]
    gen_resp = client.post(
        "/v1/drafts/generate",
        json={
            "project_id": project_id,
            "post_type": "explanation",
            "keyword": f"scope-{name}",
            "sentiment": 1,
            "draft_count": 2,
        },
        headers=headers,
    )
    assert gen_resp.status_code == 200
    return project_id, gen_resp.json()["id"]


def test_run_next_only_processes_requested_project(client, db) -> None:
    headers = _auth_headers(client, "scope-run-next")
    project_a, job_a = _seed_generation_job(client, headers, "A")
    project_b, job_b = _seed_generation_job(client, headers, "B")

    run_resp = client.post("/v1/jobs/run-next", params={"project_id": project_a}, headers=headers)
    assert run_resp.status_code == 200
    payload = run_resp.json()
    assert payload["id"] == job_a
    assert payload["status"] == "SUCCEEDED"

    job_b_row = db.get(Job, job_b)
    assert job_b_row is not None
    assert job_b_row.status == JobStatus.PENDING

    run_resp_b = client.post("/v1/jobs/run-next", params={"project_id": project_b}, headers=headers)
    assert run_resp_b.status_code == 200
    assert run_resp_b.json()["id"] == job_b
    assert run_resp_b.json()["status"] == "SUCCEEDED"


def test_run_batch_respects_limit_with_project_scope(client, db) -> None:
    headers = _auth_headers(client, "scope-run-batch")
    project_a, _ = _seed_generation_job(client, headers, "A1")
    _seed_generation_job(client, headers, "A2")

    # same user but different project to ensure scope isolation
    project_c, job_c = _seed_generation_job(client, headers, "C")

    batch_resp = client.post(
        "/v1/jobs/run-batch",
        params={"project_id": project_a, "limit": 1},
        headers=headers,
    )
    assert batch_resp.status_code == 200
    processed = batch_resp.json()
    assert len(processed) == 1
    assert processed[0]["project_id"] == project_a

    # Project C job should still remain pending until C batch/run-next is called.
    job_c_row = db.get(Job, job_c)
    assert job_c_row is not None
    assert job_c_row.status == JobStatus.PENDING

    run_c = client.post("/v1/jobs/run-next", params={"project_id": project_c}, headers=headers)
    assert run_c.status_code == 200
    assert run_c.json()["id"] == job_c
