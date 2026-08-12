import json
import re

from google import genai
from google.genai import types


POST_TYPE_LABELS = {
    "review": "리뷰",
    "explanation": "설명형",
    "impression": "소감문",
}

SENTIMENT_LABELS = {
    -2: "강한 부정",
    -1: "약한 부정",
    0: "중립",
    1: "약한 긍정",
    2: "강한 긍정",
}


def _build_prompt(keyword: str, post_type: str, sentiment: int, draft_count: int) -> str:
    post_type_label = POST_TYPE_LABELS.get(post_type, post_type)
    sentiment_label = SENTIMENT_LABELS.get(sentiment, "중립")
    return f"""
당신은 한국어 전문 블로그 작가입니다.
아래 조건으로 서로 결이 다른 블로그 초고 {draft_count}개를 작성하세요.

조건:
- 글 유형: {post_type_label}
- 핵심 키워드: {keyword}
- 감정 강도: {sentiment} ({sentiment_label})
- 첨부 이미지가 있다면 내용에 자연스럽게 반영할 것
- 각 초고는 제목 1개와 본문 Markdown으로 구성
- 본문은 도입, 소제목 3~5개, 결론을 포함
- 초고마다 관점/구성/문체가 분명히 달라야 함
- 사실을 확신할 수 없으면 단정하지 말 것
- 반드시 한국어로 작성

반드시 아래 JSON 형식으로만 응답하세요. 다른 텍스트는 포함하지 마세요.
{{
  "drafts": [
    {{"title": "...", "markdown": "# ..."}}
  ]
}}
""".strip()


def _parse_json_object(raw: str) -> dict:
    text = (raw or "").strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", text, flags=re.DOTALL)
        if not match:
            raise
        return json.loads(match.group(0))


def generate_drafts(
    *,
    api_key: str,
    model: str,
    keyword: str,
    post_type: str,
    sentiment: int,
    draft_count: int,
    image_bytes: bytes | None = None,
    image_mime_type: str | None = None,
) -> list[dict[str, str]]:
    if not api_key:
        raise ValueError("GEMINI_API_KEY is missing.")

    draft_count = 2 if draft_count < 2 else 3 if draft_count > 3 else draft_count
    prompt = _build_prompt(keyword, post_type, sentiment, draft_count)

    contents: list = [prompt]
    if image_bytes:
        contents.append(types.Part.from_bytes(data=image_bytes, mime_type=image_mime_type or "image/jpeg"))

    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model=model,
        contents=contents,
        config=types.GenerateContentConfig(response_mime_type="application/json"),
    )

    parsed = _parse_json_object(response.text)
    drafts = parsed.get("drafts", [])
    if len(drafts) < draft_count:
        raise ValueError(f"Gemini returned {len(drafts)} drafts, expected at least {draft_count}")

    return [
        {"title": str(item["title"]).strip(), "markdown": str(item["markdown"]).strip()}
        for item in drafts[:draft_count]
    ]
