from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


DEFAULT_AUTH_SECRET_KEY = "change-me-dev-secret"


class Settings(BaseSettings):
    app_env: str = "development"
    database_url: str = "postgresql+psycopg://blogsnap:blogsnap@localhost:55432/blogsnap"
    api_title: str = "BlogSnap API"
    api_version: str = "0.1.0"
    worker_poll_seconds: int = 3
    worker_batch_size: int = 10
    log_level: str = "INFO"
    prometheus_enabled: bool = True
    worker_publish_mode: str = "mock"
    worker_mock_publish_base_url: str = "https://example.com/mock-post"
    wordpress_base_url: str = ""
    wordpress_username: str = ""
    wordpress_app_password: str = ""
    tistory_api_url: str = "https://www.tistory.com/apis/post/write"
    tistory_access_token: str = ""
    tistory_blog_name: str = ""
    worker_publish_default_tags: str = "자동화,AI,블로그"
    auth_secret_key: str = DEFAULT_AUTH_SECRET_KEY
    auth_token_exp_minutes: int = 120
    auth_refresh_token_exp_minutes: int = 60 * 24 * 14
    asset_max_bytes: int = 5 * 1024 * 1024
    asset_allowed_content_types: str = "image/jpeg,image/png,image/webp,image/gif"
    asset_deleted_retention_hours: int = 24
    worker_draft_mode: str = "mock"
    gemini_model: str = "gemini-3.5-flash"
    naver_client_id: str = ""
    naver_client_secret: str = ""
    naver_redirect_uri: str = "http://localhost:8000/v1/auth/naver/callback"
    naver_login_success_redirect: str = "http://localhost:5173/?naver=connected"
    naver_login_failure_redirect: str = "http://localhost:5173/?naver=error"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    @model_validator(mode="after")
    def _reject_insecure_production_secrets(self) -> "Settings":
        if self.app_env.strip().lower() not in ("production", "prod"):
            return self
        if not self.auth_secret_key or self.auth_secret_key == DEFAULT_AUTH_SECRET_KEY:
            raise ValueError(
                "AUTH_SECRET_KEY must be set to a real secret when APP_ENV=production "
                "(refusing to start with the default dev key: forging auth tokens would be trivial)."
            )
        if len(self.auth_secret_key) < 32:
            raise ValueError("AUTH_SECRET_KEY must be at least 32 characters in production.")
        return self


settings = Settings()
