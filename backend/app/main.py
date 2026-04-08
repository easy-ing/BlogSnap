from fastapi import FastAPI

from backend.app.api.drafts import router as drafts_router
from backend.app.api.health import router as health_router
from backend.app.api.jobs import router as jobs_router
from backend.app.api.publish import router as publish_router
from backend.app.core.config import settings
from backend.app.core.logging import setup_logging
from backend.app.core.middleware import RequestLoggingMiddleware


app = FastAPI(title=settings.api_title, version=settings.api_version)
setup_logging()
app.add_middleware(RequestLoggingMiddleware)

app.include_router(health_router)
app.include_router(drafts_router)
app.include_router(jobs_router)
app.include_router(publish_router)
