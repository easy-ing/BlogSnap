from __future__ import annotations

import os
import subprocess
from pathlib import Path

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
        subprocess.run([str(ROOT_DIR / "scripts/db_reset.sh")], check=True)


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
