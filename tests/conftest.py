from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

# Force deterministic, offline draft generation for the test suite regardless
# of the local .env's WORKER_DRAFT_MODE (e.g. gemini for manual/live testing).
# Must run before backend.app.core.config's Settings singleton is imported.
os.environ["WORKER_DRAFT_MODE"] = "mock"

# Tests must NEVER run against the primary dev/demo database: prepare_test_db
# below does a full DROP SCHEMA reset, which would wipe real connected API
# keys, projects, and drafts if pointed at the same DB the dev containers use.
# Force a distinct "<name>_test" database regardless of what DATABASE_URL the
# local .env has configured, before backend.app.core.config's Settings
# singleton is imported.
_base_db_url = os.environ.get(
    "DATABASE_URL", "postgresql+psycopg://blogsnap:blogsnap@localhost:55432/blogsnap"
)
_test_db_url = re.sub(r"/([^/]+)$", lambda m: f"/{m.group(1)}_test", _base_db_url)
os.environ["DATABASE_URL"] = _test_db_url
TEST_DB_NAME = _test_db_url.rsplit("/", 1)[-1]

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from backend.app.db.session import SessionLocal
from backend.app.main import app


ROOT_DIR = Path(__file__).resolve().parents[1]


@pytest.fixture(scope="session", autouse=True)
def prepare_test_db() -> None:
    reset_mode = os.getenv("TEST_DB_RESET_MODE", "docker").strip().lower()
    if reset_mode == "docker":
        env = {**os.environ, "DB_NAME": TEST_DB_NAME}
        subprocess.run([str(ROOT_DIR / "scripts/db_reset.sh")], check=True, env=env)


@pytest.fixture()
def db():
    with SessionLocal() as session:
        session.execute(text("TRUNCATE TABLE users CASCADE"))
        session.commit()
        yield session
        session.execute(text("TRUNCATE TABLE users CASCADE"))
        session.commit()


@pytest.fixture()
def client() -> TestClient:
    with TestClient(app) as tc:
        yield tc
