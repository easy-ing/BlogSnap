import uuid
from datetime import datetime
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from backend.app.core.config import settings
from backend.app.models.entities import Asset, Draft, Job, Project, PublishJob, User
from backend.app.models.enums import DraftStatus, JobType, ProviderType, PublishStatus, ScheduleStatus
from backend.app.services.gemini_writer import generate_drafts
from backend.app.services.secret_crypto import decrypt_secret
from backend.app.worker.publishers import publish_to_tistory, publish_to_wordpress


UPLOAD_ROOT = Path("tmp/uploads")


def _next_version_no(db: Session, project_id: uuid.UUID) -> int:
    value = db.scalar(select(func.max(Draft.version_no)).where(Draft.project_id == project_id))
    return (value or 0) + 1


def _build_mock_markdown(keyword: str, sentiment: int, post_type: str, variant_no: int) -> str:
    sentiment_text = {
        -2: "강한 부정",
        -1: "약한 부정",
        0: "중립",
        1: "약한 긍정",
        2: "강한 긍정",
    }.get(sentiment, "중립")
    return (
        f"# {keyword} {variant_no}안\n\n"
        f"- 글 유형: {post_type}\n"
        f"- 감정 강도: {sentiment_text}\n\n"
        "## 도입\n"
        "핵심 포인트를 간단히 정리합니다.\n\n"
        "## 본문\n"
        "실행 가능한 팁과 예시를 담습니다.\n\n"
        "## 결론\n"
        "핵심 요약과 다음 액션을 제시합니다.\n"
    )


def _get_owner_gemini_key(db: Session, project_id: uuid.UUID) -> str:
    owner = db.scalar(
        select(User).join(Project, Project.user_id == User.id).where(Project.id == project_id)
    )
    if not owner or not owner.gemini_api_key_encrypted:
        raise ValueError(
            "Gemini API 키가 연결되어 있지 않습니다. 설정에서 본인의 Gemini API 키를 먼저 연결해주세요."
        )
    return decrypt_secret(owner.gemini_api_key_encrypted)


def _load_image(db: Session, image_asset_id: str | None) -> tuple[bytes | None, str | None]:
    if not image_asset_id:
        return None, None
    asset = db.get(Asset, uuid.UUID(image_asset_id))
    if not asset:
        return None, None
    file_path = UPLOAD_ROOT / asset.storage_key
    if not file_path.exists():
        return None, None
    return file_path.read_bytes(), asset.content_type


def _generate_mock_drafts(keyword: str, sentiment: int, post_type: str, draft_count: int) -> list[dict[str, str]]:
    return [
        {"title": f"{keyword} {variant_no}안", "markdown": _build_mock_markdown(keyword, sentiment, post_type, variant_no)}
        for variant_no in range(1, draft_count + 1)
    ]


def _execute_draft_job(db: Session, job: Job) -> dict:
    payload = job.request_payload or {}
    keyword = str(payload.get("keyword", "키워드"))
    sentiment = int(payload.get("sentiment", 0))
    post_type = str(payload.get("post_type", "explanation"))
    draft_count = int(payload.get("draft_count", 3))
    draft_count = 2 if draft_count < 2 else 3 if draft_count > 3 else draft_count

    mode = settings.worker_draft_mode.strip().lower()
    if mode == "gemini":
        user_api_key = _get_owner_gemini_key(db, job.project_id)
        image_bytes, image_mime_type = _load_image(db, payload.get("image_asset_id"))
        drafts_data = generate_drafts(
            api_key=user_api_key,
            model=settings.gemini_model,
            keyword=keyword,
            post_type=post_type,
            sentiment=sentiment,
            draft_count=draft_count,
            image_bytes=image_bytes,
            image_mime_type=image_mime_type,
        )
    elif mode == "mock":
        drafts_data = _generate_mock_drafts(keyword, sentiment, post_type, draft_count)
    else:
        raise ValueError(f"Unsupported worker draft mode: {settings.worker_draft_mode}")

    version_no = _next_version_no(db, job.project_id)
    created_ids: list[str] = []

    for variant_no, item in enumerate(drafts_data, start=1):
        draft = Draft(
            project_id=job.project_id,
            source_job_id=job.id,
            post_type=post_type,
            keyword=keyword,
            sentiment=sentiment,
            title=item["title"],
            markdown=item["markdown"],
            version_no=version_no,
            variant_no=variant_no,
            status=DraftStatus.GENERATED,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(draft)
        db.flush()
        created_ids.append(str(draft.id))

    return {"draft_ids": created_ids, "version_no": version_no}


def _execute_publish_job(db: Session, job: Job) -> dict:
    publish_job = db.scalar(select(PublishJob).where(PublishJob.job_id == job.id))
    if not publish_job:
        raise ValueError("PublishJob not found for job")

    draft = db.get(Draft, publish_job.draft_id)
    if not draft:
        raise ValueError("Draft not found for publish job")

    mode = settings.worker_publish_mode.strip().lower()
    provider = publish_job.provider
    tags = [t.strip() for t in settings.worker_publish_default_tags.split(",") if t.strip()]

    if mode == "mock":
        publish_job.status = PublishStatus.PUBLISHED
        publish_job.external_post_id = str(publish_job.id)
        publish_job.post_url = f"{settings.worker_mock_publish_base_url}/{provider.value}/{publish_job.id}"
        publish_job.response_snapshot = {
            "mode": "mock",
            "provider": provider.value,
            "external_post_id": publish_job.external_post_id,
            "post_url": publish_job.post_url,
        }
    elif mode == "wordpress":
        if provider != ProviderType.wordpress:
            raise ValueError("worker_publish_mode=wordpress requires provider=wordpress")
        external_id, post_url = publish_to_wordpress(
            base_url=settings.wordpress_base_url,
            username=settings.wordpress_username,
            app_password=settings.wordpress_app_password,
            title=draft.title,
            markdown=draft.markdown,
            tags=tags,
        )
        publish_job.status = PublishStatus.PUBLISHED
        publish_job.external_post_id = external_id
        publish_job.post_url = post_url
        publish_job.response_snapshot = {
            "mode": "wordpress",
            "provider": provider.value,
            "external_post_id": external_id,
            "post_url": post_url,
        }
    elif mode == "tistory":
        if provider != ProviderType.tistory:
            raise ValueError("worker_publish_mode=tistory requires provider=tistory")
        external_id, post_url = publish_to_tistory(
            api_url=settings.tistory_api_url,
            access_token=settings.tistory_access_token,
            blog_name=settings.tistory_blog_name,
            title=draft.title,
            markdown=draft.markdown,
            tags=tags,
        )
        publish_job.status = PublishStatus.PUBLISHED
        publish_job.external_post_id = external_id
        publish_job.post_url = post_url
        publish_job.response_snapshot = {
            "mode": "tistory",
            "provider": provider.value,
            "external_post_id": external_id,
            "post_url": post_url,
        }
    elif mode == "live":
        if provider == ProviderType.wordpress:
            external_id, post_url = publish_to_wordpress(
                base_url=settings.wordpress_base_url,
                username=settings.wordpress_username,
                app_password=settings.wordpress_app_password,
                title=draft.title,
                markdown=draft.markdown,
                tags=tags,
            )
        elif provider == ProviderType.tistory:
            external_id, post_url = publish_to_tistory(
                api_url=settings.tistory_api_url,
                access_token=settings.tistory_access_token,
                blog_name=settings.tistory_blog_name,
                title=draft.title,
                markdown=draft.markdown,
                tags=tags,
            )
        else:
            raise ValueError(f"Unsupported provider in live mode: {provider}")

        publish_job.status = PublishStatus.PUBLISHED
        publish_job.external_post_id = external_id
        publish_job.post_url = post_url
        publish_job.response_snapshot = {
            "mode": "live",
            "provider": provider.value,
            "external_post_id": external_id,
            "post_url": post_url,
        }
    else:
        raise ValueError(f"Unsupported worker publish mode: {settings.worker_publish_mode}")

    publish_job.updated_at = datetime.utcnow()
    if publish_job.schedule_status != ScheduleStatus.CANCELLED:
        publish_job.schedule_status = ScheduleStatus.READY

    return {
        "publish_job_id": str(publish_job.id),
        "post_url": publish_job.post_url,
        "mode": mode,
        "provider": provider.value,
    }


def execute_job(db: Session, job: Job) -> dict:
    if job.type in (JobType.draft_generate, JobType.draft_regenerate):
        return _execute_draft_job(db, job)
    if job.type == JobType.publish:
        return _execute_publish_job(db, job)
    raise ValueError(f"Unsupported job type: {job.type}")
