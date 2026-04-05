from backend.app.db.session import SessionLocal
from backend.app.worker.runner import JobRunner


def main() -> None:
    db = SessionLocal()
    try:
        runner = JobRunner(db)
        job = runner.run_next()
        if not job:
            print("[INFO] No runnable jobs.")
            return
        print(f"[OK] Processed job: {job.id} status={job.status}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
