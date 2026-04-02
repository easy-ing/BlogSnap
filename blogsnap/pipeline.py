import argparse
import json
from pathlib import Path

from blogsnap.ai_writer import AIWriter
from blogsnap.blog_clients.wordpress import WordPressClient
from blogsnap.config import load_settings
from blogsnap.schemas import BlogInput


def _load_input(input_path: str) -> BlogInput:
    path = Path(input_path)
    if not path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    blog_input = BlogInput.model_validate(data)
    image_path = Path(blog_input.image_path)
    if not image_path.is_absolute():
        blog_input.image_path = str((path.parent / image_path).resolve())

    return blog_input


def run_pipeline() -> None:
    parser = argparse.ArgumentParser(description="Generate and upload blog posts automatically.")
    parser.add_argument("--input", required=True, help="Path to JSON input file")
    parser.add_argument("--dry-run", action="store_true", help="Generate only, do not upload")
    parser.add_argument("--save", default="generated_post.md", help="Where to save generated markdown")
    args = parser.parse_args()

    settings = load_settings()
    blog_input = _load_input(args.input)

    writer = AIWriter(api_key=settings.openai_api_key, model=settings.openai_model)
    markdown = writer.generate_markdown(blog_input)

    save_path = Path(args.save)
    save_path.write_text(markdown, encoding="utf-8")
    print(f"[OK] Markdown saved: {save_path.resolve()}")

    if args.dry_run:
        print("[DRY-RUN] Upload skipped.")
        return

    if settings.blog_provider != "wordpress":
        raise ValueError(f"Unsupported BLOG_PROVIDER: {settings.blog_provider}")

    client = WordPressClient(
        base_url=settings.blog_base_url,
        username=settings.blog_username,
        app_password=settings.blog_app_password,
    )

    title = blog_input.title or ""
    url = client.upload_post(
        title=title,
        markdown=markdown,
        image_path=blog_input.image_path,
        tags=settings.default_tags,
        category=settings.default_category,
    )

    print(f"[OK] Post published: {url}")
