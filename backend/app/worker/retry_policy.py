from datetime import datetime, timedelta, timezone
from random import randint

from backend.app.models.enums import JobType


def _policy(job_type: JobType) -> tuple[int, int]:
    if job_type in (JobType.draft_generate, JobType.draft_regenerate):
        return 5, 60
    if job_type == JobType.publish:
        return 10, 120
    return 5, 60


def compute_next_retry_at(job_type: JobType, attempt: int) -> datetime:
    base, max_delay = _policy(job_type)
    jitter = randint(0, 3)
    delay_seconds = min(base * (2 ** max(attempt - 1, 0)) + jitter, max_delay)
    return datetime.now(timezone.utc) + timedelta(seconds=delay_seconds)


def is_retryable(exc: Exception) -> bool:
    non_retryable = (ValueError, FileNotFoundError)
    return not isinstance(exc, non_retryable)
