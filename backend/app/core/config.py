from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://blogsnap:blogsnap@localhost:55432/blogsnap"
    api_title: str = "BlogSnap API"
    api_version: str = "0.1.0"
    worker_poll_seconds: int = 3
    worker_batch_size: int = 10
    log_level: str = "INFO"
    worker_publish_mode: str = "mock"
    worker_mock_publish_base_url: str = "https://example.com/mock-post"
    wordpress_base_url: str = ""
    wordpress_username: str = ""
    wordpress_app_password: str = ""
    worker_publish_default_tags: str = "자동화,AI,블로그"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


settings = Settings()
