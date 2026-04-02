import mimetypes
from pathlib import Path
from typing import Optional, Tuple

import markdown as md
import requests

from blogsnap.blog_clients.base import BlogClient


class WordPressClient(BlogClient):
    def __init__(self, base_url: str, username: str, app_password: str) -> None:
        if not base_url or not username or not app_password:
            raise ValueError("WordPress credentials are missing.")

        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.auth = (username, app_password)

    @staticmethod
    def _extract_title(markdown: str) -> str:
        for line in markdown.splitlines():
            if line.startswith("# "):
                return line.replace("# ", "", 1).strip()
        return "자동 생성 포스트"

    @staticmethod
    def _markdown_to_html(markdown: str) -> str:
        return md.markdown(markdown, extensions=["extra", "sane_lists"])

    def _upload_media(self, image_path: str) -> Tuple[Optional[int], str]:
        path = Path(image_path)
        if not path.exists():
            return None, ""

        mime_type, _ = mimetypes.guess_type(str(path))
        mime_type = mime_type or "image/jpeg"
        media_url = f"{self.base_url}/wp-json/wp/v2/media"

        headers = {
            "Content-Disposition": f'attachment; filename="{path.name}"',
            "Content-Type": mime_type,
        }
        resp = self.session.post(media_url, headers=headers, data=path.read_bytes(), timeout=40)
        resp.raise_for_status()

        media = resp.json()
        return media.get("id"), media.get("source_url", "")

    def _ensure_tag_ids(self, tags: list[str]) -> list[int]:
        tag_ids: list[int] = []
        for tag in tags:
            tag = tag.strip()
            if not tag:
                continue

            search_url = f"{self.base_url}/wp-json/wp/v2/tags"
            resp = self.session.get(search_url, params={"search": tag, "per_page": 100}, timeout=20)
            resp.raise_for_status()
            candidates = resp.json()
            found = next((item for item in candidates if item.get("name", "").lower() == tag.lower()), None)

            if found:
                tag_ids.append(found["id"])
                continue

            create_resp = self.session.post(search_url, json={"name": tag}, timeout=20)
            create_resp.raise_for_status()
            tag_ids.append(create_resp.json()["id"])

        return tag_ids

    def upload_post(
        self,
        *,
        title: str,
        markdown: str,
        image_path: str,
        tags: list[str],
        category: str = "",
    ) -> str:
        if not title:
            title = self._extract_title(markdown)

        content_html = self._markdown_to_html(markdown)
        media_id, media_url = self._upload_media(image_path)
        if media_url:
            content_html = f'<p><img src="{media_url}" alt="{title}"></p>\n{content_html}'
        tag_ids = self._ensure_tag_ids(tags)

        payload = {
            "title": title,
            "content": content_html,
            "status": "publish",
            "tags": tag_ids,
        }
        if media_id:
            payload["featured_media"] = media_id

        create_post_url = f"{self.base_url}/wp-json/wp/v2/posts"
        resp = self.session.post(create_post_url, json=payload, timeout=30)
        resp.raise_for_status()

        data = resp.json()
        return data.get("link", "")
