import uuid

from sqlalchemy import select

from backend.app.db.session import SessionLocal
from backend.app.models.entities import Job, Project, User
from backend.app.models.enums import JobStatus, JobType



def main() -> None:
    db = SessionLocal()
    try:
        email = "day4-demo@blogsnap.local"
        user = db.scalar(select(User).where(User.email == email))
        if not user:
            user = User(email=email, display_name="Day4 Demo")
            db.add(user)
            db.flush()

        project = db.scalar(select(Project).where(Project.user_id == user.id, Project.name == "Day4 Project"))
        if not project:
            project = Project(user_id=user.id, name="Day4 Project")
            db.add(project)
            db.flush()

        job = Job(
            project_id=project.id,
            type=JobType.draft_generate,
            status=JobStatus.PENDING,
            request_payload={
                "project_id": str(project.id),
                "post_type": "explanation",
                "keyword": "Day4 자동화 테스트",
                "sentiment": 1,
                "draft_count": 3,
                "idempotency_key": str(uuid.uuid4()),
            },
            max_attempts=3,
        )
        db.add(job)
        db.commit()
        db.refresh(job)

        print(f"[OK] Seeded project={project.id}")
        print(f"[OK] Seeded job={job.id}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
