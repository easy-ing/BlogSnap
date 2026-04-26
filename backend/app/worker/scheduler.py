from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from backend.app.models.entities import Job, PublishJob
from backend.app.models.enums import JobStatus, ScheduleStatus


def reconcile_scheduled_publish_jobs(
    db: Session,
    *,
    project_id: Optional[UUID] = None,
) -> dict:
    now = datetime.now(timezone.utc)
    stmt = select(PublishJob).where(PublishJob.schedule_status == ScheduleStatus.SCHEDULED)
    if project_id:
        stmt = stmt.where(PublishJob.project_id == project_id)
    scheduled_jobs = list(db.scalars(stmt))

    scanned = len(scheduled_jobs)
    activated = 0
    waiting = 0

    for publish_job in scheduled_jobs:
        linked_job = db.get(Job, publish_job.job_id) if publish_job.job_id else None

        # Skip invalid schedule entries defensively and keep them runnable.
        if publish_job.scheduled_at is None:
            publish_job.schedule_status = ScheduleStatus.READY
            publish_job.updated_at = now
            if linked_job and linked_job.status in (JobStatus.RETRYING, JobStatus.PENDING):
                linked_job.status = JobStatus.PENDING
                linked_job.next_retry_at = None
                linked_job.updated_at = now
            activated += 1
            continue

        # Time reached: move to runnable state.
        if publish_job.scheduled_at <= now:
            publish_job.schedule_status = ScheduleStatus.READY
            publish_job.updated_at = now
            if linked_job and linked_job.status in (JobStatus.RETRYING, JobStatus.PENDING):
                linked_job.status = JobStatus.PENDING
                linked_job.next_retry_at = None
                linked_job.error_message = None
                linked_job.updated_at = now
            activated += 1
            continue

        # Still in future: enforce retry gate timestamp.
        if linked_job and linked_job.status in (JobStatus.PENDING, JobStatus.RETRYING):
            linked_job.status = JobStatus.RETRYING
            linked_job.next_retry_at = publish_job.scheduled_at
            linked_job.updated_at = now
        waiting += 1

    db.commit()
    return {
        "project_id": str(project_id) if project_id else None,
        "scanned": scanned,
        "activated": activated,
        "waiting": waiting,
    }
