from abc import ABC, abstractmethod


class BlogClient(ABC):
    @abstractmethod
    def upload_post(
        self,
        *,
        title: str,
        markdown: str,
        image_path: str,
        tags: list[str],
        category: str = "",
    ) -> str:
        """Upload a post and return URL."""
