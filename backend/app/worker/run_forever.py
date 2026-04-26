import argparse
import time

from backend.app.core.config import settings
from backend.app.db.session import SessionLocal
from backend.app.worker.runner import JobRunner


def run_forever(max_loops: int = 0) -> None:
    loops = 0
    while True:
        db = SessionLocal()
        try:
            runner = JobRunner(db)
            reconciled = runner.reconcile_schedules()
            processed = runner.run_batch(limit=settings.worker_batch_size)
        finally:
            db.close()

        if reconciled.get("activated", 0) > 0:
            print(
                f"[INFO] schedules-activated={reconciled['activated']} "
                f"waiting={reconciled['waiting']}"
            )

        if processed:
            print(f"[INFO] processed={len(processed)}")
        else:
            print("[INFO] no-runnable-jobs")

        loops += 1
        if max_loops > 0 and loops >= max_loops:
            print("[INFO] reached max loops, exiting")
            return
        time.sleep(max(settings.worker_poll_seconds, 1))


def main() -> None:
    parser = argparse.ArgumentParser(description="Run worker in polling loop.")
    parser.add_argument("--max-loops", type=int, default=0, help="Stop after N loops (0 means infinite)")
    args = parser.parse_args()
    run_forever(max_loops=args.max_loops)


if __name__ == "__main__":
    main()
