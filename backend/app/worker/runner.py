from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from backend.app.models.entities import Job, PublishJob
from backend.app.models.enums import JobStatus, JobType, PublishStatus, ScheduleStatus
from backend.app.core.metrics import JOB_PROCESSED
from backend.app.worker.executor import execute_job
from backend.app.worker.retry_policy import compute_next_retry_at, is_retryable
from backend.app.worker.scheduler import reconcile_scheduled_publish_jobs


class JobRunner:
    def __init__(self, db: Session) -> None:
        self.db = db

    def claim_next_job(self, *, project_id: Optional[UUID] = None) -> Optional[Job]:
        now = datetime.now(timezone.utc)
        stmt = select(Job).where(
            Job.status.in_([JobStatus.PENDING, JobStatus.RETRYING]),
            or_(Job.next_retry_at.is_(None), Job.next_retry_at <= now),
        )
        if project_id:
            stmt = stmt.where(Job.project_id == project_id)
        stmt = stmt.order_by(Job.created_at.asc()).limit(1).with_for_update(skip_locked=True)

        job = self.db.scalar(stmt)
        if not job:
            return None

        job.status = JobStatus.RUNNING
        job.attempt_count = (job.attempt_count or 0) + 1
        job.started_at = now
        job.updated_at = now
        self.db.commit()
        self.db.refresh(job)
        return job

    def run_job_by_id(self, job_id: UUID) -> Job:
        job = self.db.get(Job, job_id)
        if not job:
            raise ValueError("Job not found")

        if job.status not in (JobStatus.PENDING, JobStatus.RETRYING, JobStatus.RUNNING):
            return job

        if job.type == JobType.publish:
            publish_job = self.db.scalar(select(PublishJob).where(PublishJob.job_id == job.id))
            if publish_job and publish_job.schedule_status == ScheduleStatus.CANCELLED:
                now = datetime.now(timezone.utc)
                job.status = JobStatus.FAILED
                job.error_message = "Publish job cancelled by user"
                job.completed_at = now
                job.next_retry_at = None
                job.updated_at = now
                publish_job.status = PublishStatus.ERROR
                publish_job.error_message = "Cancelled by user"
                publish_job.updated_at = now
                self.db.commit()
                self.db.refresh(job)
                return job

        now = datetime.now(timezone.utc)
        if job.status == JobStatus.RETRYING and job.next_retry_at and job.next_retry_at > now:
            return job

        if job.status != JobStatus.RUNNING:
            job.status = JobStatus.RUNNING
            job.attempt_count = (job.attempt_count or 0) + 1
            job.started_at = now
            job.updated_at = now
            self.db.commit()
            self.db.refresh(job)

        return self._execute_with_retry(job)

    def run_next(self, *, project_id: Optional[UUID] = None) -> Optional[Job]:
        job = self.claim_next_job(project_id=project_id)
        if not job:
            return None
        return self._execute_with_retry(job)

    def run_batch(self, limit: int = 10, *, project_id: Optional[UUID] = None) -> list[Job]:
        if limit < 1:
            return []
        processed: list[Job] = []
        for _ in range(limit):
            job = self.run_next(project_id=project_id)
            if not job:
                break
            processed.append(job)
        return processed

    def reconcile_schedules(self, *, project_id: Optional[UUID] = None) -> dict:
        return reconcile_scheduled_publish_jobs(self.db, project_id=project_id)

    def _execute_with_retry(self, job: Job) -> Job:
        try:
            result = execute_job(self.db, job)
            now = datetime.now(timezone.utc)
            job.result_payload = result
            job.status = JobStatus.SUCCEEDED
            job.error_message = None
            job.next_retry_at = None
            job.completed_at = now
            job.updated_at = now
            self.db.commit()
            self.db.refresh(job)
            JOB_PROCESSED.labels(job_type=job.type.value, outcome="succeeded").inc()
            return job
        except Exception as exc:
            now = datetime.now(timezone.utc)
            job.error_message = str(exc)
            job.updated_at = now

            can_retry = is_retryable(exc) and job.attempt_count < job.max_attempts
            if can_retry:
                job.status = JobStatus.RETRYING
                job.next_retry_at = compute_next_retry_at(job.type, job.attempt_count)
                JOB_PROCESSED.labels(job_type=job.type.value, outcome="retrying").inc()
            else:
                job.status = JobStatus.FAILED
                job.completed_at = now
                job.next_retry_at = None
                JOB_PROCESSED.labels(job_type=job.type.value, outcome="failed").inc()

            self.db.commit()
            self.db.refresh(job)
            return job
