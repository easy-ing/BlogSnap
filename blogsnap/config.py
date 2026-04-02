import os
from dataclasses import dataclass

from dotenv import load_dotenv


load_dotenv()


@dataclass
class Settings:
    openai_api_key: str
    openai_model: str
    blog_provider: str
    blog_base_url: str
    blog_username: str
    blog_app_password: str
    default_category: str
    default_tags: list[str]



def load_settings() -> Settings:
    tags_raw = os.getenv("DEFAULT_TAGS", "")
    tags = [tag.strip() for tag in tags_raw.split(",") if tag.strip()]

    return Settings(
        openai_api_key=os.getenv("OPENAI_API_KEY", ""),
        openai_model=os.getenv("OPENAI_MODEL", "gpt-5-mini"),
        blog_provider=os.getenv("BLOG_PROVIDER", "wordpress").lower(),
        blog_base_url=os.getenv("BLOG_BASE_URL", "").rstrip("/"),
        blog_username=os.getenv("BLOG_USERNAME", ""),
        blog_app_password=os.getenv("BLOG_APP_PASSWORD", ""),
        default_category=os.getenv("DEFAULT_CATEGORY", ""),
        default_tags=tags,
    )
