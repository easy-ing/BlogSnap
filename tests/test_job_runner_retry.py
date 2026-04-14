from __future__ import annotations

import uuid

from backend.app.models.entities import Job, Project, User
from backend.app.models.enums import JobStatus, JobType
from backend.app.worker.runner import JobRunner


def _seed_job(db, *, max_attempts: int = 3) -> Job:
    user = User(email=f"retry-{uuid.uuid4()}@blogsnap.local", display_name="Retry Test")
    db.add(user)
    db.flush()
    project = Project(user_id=user.id, name="Retry Project")
    db.add(project)
    db.flush()
    job = Job(
        project_id=project.id,
        type=JobType.draft_generate,
        status=JobStatus.PENDING,
        max_attempts=max_attempts,
        request_payload={
            "project_id": str(project.id),
            "post_type": "review",
            "keyword": "retry",
            "sentiment": 0,
            "draft_count": 2,
        },
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


def test_retryable_error_moves_job_to_retrying(db, monkeypatch) -> None:
    job = _seed_job(db, max_attempts=3)

    def _raise_retryable(*args, **kwargs):
        raise RuntimeError("transient fail")

    monkeypatch.setattr("backend.app.worker.runner.execute_job", _raise_retryable)
    runner = JobRunner(db)
    result = runner.run_job_by_id(job.id)

    assert result.status == JobStatus.RETRYING
    assert result.attempt_count == 1
    assert result.next_retry_at is not None
    assert result.error_message == "transient fail"


def test_non_retryable_error_moves_job_to_failed(db, monkeypatch) -> None:
    job = _seed_job(db, max_attempts=3)

    def _raise_non_retryable(*args, **kwargs):
        raise ValueError("bad payload")

    monkeypatch.setattr("backend.app.worker.runner.execute_job", _raise_non_retryable)
    runner = JobRunner(db)
    result = runner.run_job_by_id(job.id)

    assert result.status == JobStatus.FAILED
    assert result.attempt_count == 1
    assert result.completed_at is not None
    assert result.next_retry_at is None
    assert result.error_message == "bad payload"
