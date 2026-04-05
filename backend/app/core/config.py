from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://blogsnap:blogsnap@localhost:55432/blogsnap"
    api_title: str = "BlogSnap API"
    api_version: str = "0.1.0"
    worker_poll_seconds: int = 3
    worker_publish_mode: str = "mock"
    worker_mock_publish_base_url: str = "https://example.com/mock-post"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


settings = Settings()
