from typing import List, Tuple

import markdown as md
import requests


def markdown_to_html(text: str) -> str:
    return md.markdown(text, extensions=["extra", "sane_lists"])


def _ensure_tag_ids(session: requests.Session, base_url: str, tags: List[str]) -> List[int]:
    tag_ids: List[int] = []
    for tag in tags:
        name = tag.strip()
        if not name:
            continue
        endpoint = f"{base_url}/wp-json/wp/v2/tags"
        resp = session.get(endpoint, params={"search": name, "per_page": 100}, timeout=20)
        resp.raise_for_status()
        found = next((t for t in resp.json() if t.get("name", "").lower() == name.lower()), None)
        if found:
            tag_ids.append(found["id"])
            continue
        created = session.post(endpoint, json={"name": name}, timeout=20)
        created.raise_for_status()
        tag_ids.append(created.json()["id"])
    return tag_ids


def publish_to_wordpress(
    *,
    base_url: str,
    username: str,
    app_password: str,
    title: str,
    markdown: str,
    tags: List[str],
) -> Tuple[str, str]:
    if not base_url or not username or not app_password:
        raise ValueError("WordPress credentials are missing for worker publish mode.")

    session = requests.Session()
    session.auth = (username, app_password)
    base = base_url.rstrip("/")

    content_html = markdown_to_html(markdown)
    tag_ids = _ensure_tag_ids(session, base, tags)

    payload = {
        "title": title,
        "content": content_html,
        "status": "publish",
        "tags": tag_ids,
    }
    resp = session.post(f"{base}/wp-json/wp/v2/posts", json=payload, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    return str(data.get("id", "")), str(data.get("link", ""))


def publish_to_tistory(
    *,
    api_url: str,
    access_token: str,
    blog_name: str,
    title: str,
    markdown: str,
    tags: List[str],
) -> Tuple[str, str]:
    if not api_url or not access_token or not blog_name:
        raise ValueError("Tistory credentials are missing for tistory publish mode.")

    content_html = markdown_to_html(markdown)
    payload = {
        "access_token": access_token,
        "output": "json",
        "blogName": blog_name,
        "title": title,
        "content": content_html,
        "visibility": 3,
    }
    if tags:
        payload["tag"] = ",".join(tags)

    resp = requests.post(api_url, data=payload, timeout=30)
    resp.raise_for_status()
    data = resp.json()

    # Expected Tistory response shape:
    # {"tistory":{"status":"200","postId":"...","url":"..."}}
    tistory_obj = data.get("tistory", {}) if isinstance(data, dict) else {}
    external_id = str(tistory_obj.get("postId", ""))
    post_url = str(tistory_obj.get("url", ""))

    if not external_id and not post_url:
        raise ValueError("Unexpected Tistory response payload")
    return external_id, post_url
