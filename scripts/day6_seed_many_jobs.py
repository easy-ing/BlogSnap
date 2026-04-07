import uuid

from sqlalchemy import select

from backend.app.db.session import SessionLocal
from backend.app.models.entities import Job, Project, User
from backend.app.models.enums import JobStatus, JobType


def main(count: int = 5) -> None:
    db = SessionLocal()
    try:
        email = "day6-demo@blogsnap.local"
        user = db.scalar(select(User).where(User.email == email))
        if not user:
            user = User(email=email, display_name="Day6 Demo")
            db.add(user)
            db.flush()

        project = db.scalar(select(Project).where(Project.user_id == user.id, Project.name == "Day6 Project"))
        if not project:
            project = Project(user_id=user.id, name="Day6 Project")
            db.add(project)
            db.flush()

        for idx in range(count):
            job = Job(
                project_id=project.id,
                type=JobType.draft_generate,
                status=JobStatus.PENDING,
                request_payload={
                    "project_id": str(project.id),
                    "post_type": "explanation",
                    "keyword": f"Day6 배치 테스트 {idx+1}",
                    "sentiment": 0,
                    "draft_count": 2,
                    "idempotency_key": str(uuid.uuid4()),
                },
                max_attempts=3,
            )
            db.add(job)

        db.commit()
        print(f"[OK] Seeded {count} jobs for project={project.id}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
