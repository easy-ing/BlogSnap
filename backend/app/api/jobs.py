from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from backend.app.db.session import get_db
from backend.app.models.entities import Job
from backend.app.schemas.jobs import JobResponse
from backend.app.worker.runner import JobRunner


router = APIRouter(prefix="/v1/jobs", tags=["jobs"])


@router.get("/{job_id}", response_model=JobResponse)
def get_job(job_id: UUID, db: Session = Depends(get_db)) -> Job:
    job = db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job


@router.post("/{job_id}/run", response_model=JobResponse)
def run_job(job_id: UUID, db: Session = Depends(get_db)) -> Job:
    runner = JobRunner(db)
    try:
        return runner.run_job_by_id(job_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/run-next", response_model=JobResponse)
def run_next_job(db: Session = Depends(get_db)) -> Job:
    runner = JobRunner(db)
    job = runner.run_next()
    if not job:
        raise HTTPException(status_code=404, detail="No runnable jobs")
    return job
