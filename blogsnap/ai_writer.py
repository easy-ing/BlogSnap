import base64
import json
import mimetypes
import re
from pathlib import Path

from openai import OpenAI

from blogsnap.schemas import BlogInput, DraftBundle, DraftRequest


class AIWriter:
    def __init__(self, api_key: str, model: str) -> None:
        if not api_key:
            raise ValueError("OPENAI_API_KEY is missing.")
        self.client = OpenAI(api_key=api_key)
        self.model = model

    @staticmethod
    def _to_data_url(image_path: str) -> str:
        path = Path(image_path)
        if not path.exists():
            raise FileNotFoundError(f"Image file not found: {image_path}")

        mime_type, _ = mimetypes.guess_type(str(path))
        mime_type = mime_type or "image/jpeg"

        encoded = base64.b64encode(path.read_bytes()).decode("utf-8")
        return f"data:{mime_type};base64,{encoded}"

    def generate_markdown(self, data: BlogInput) -> str:
        image_data_url = self._to_data_url(data.image_path)

        prompt = f"""
You are a Korean blog writer.
Write a polished Korean blog post in Markdown based on the user input.

Requirements:
- Tone: {data.tone}
- Main keyword: {data.keyword}
- If title is provided, use it: {data.title or "(none)"}
- Add practical examples and actionable tips.
- Make it natural for Korean readers.
- Include a short intro, 3-5 section headings, and a conclusion.
- Add a call-to-action at the end: {data.cta or "댓글로 의견을 남겨주세요."}
- Avoid hallucinating factual claims. If uncertain, phrase carefully.
""".strip()

        response = self.client.responses.create(
            model=self.model,
            input=[
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": prompt},
                        {"type": "input_image", "image_url": image_data_url},
                    ],
                }
            ],
            text={"format": {"type": "text"}},
        )

        return response.output_text.strip()

    def generate_drafts(self, req: DraftRequest, count: int = 3) -> DraftBundle:
        image_data_url = self._to_data_url(req.image_path)
        count = 2 if count < 2 else 3 if count > 3 else count

        post_type_map = {
            "review": "리뷰",
            "explanation": "설명형",
            "impression": "소감문",
        }
        sentiment_guide = {
            -2: "강한 부정",
            -1: "약한 부정",
            0: "중립",
            1: "약한 긍정",
            2: "강한 긍정",
        }

        prompt = f"""
당신은 한국어 전문 블로그 작가입니다.
아래 조건으로 서로 결이 다른 블로그 초고 {count}개를 작성하세요.

조건:
- 글 유형: {post_type_map[req.post_type]}
- 핵심 키워드: {req.keyword}
- 감정 강도: {req.sentiment} ({sentiment_guide[req.sentiment]})
- CTA: {req.cta or "댓글로 의견을 남겨주세요."}
- 각 초고는 제목 1개와 본문 Markdown으로 구성
- 본문은 도입, 소제목 3~5개, 결론 포함
- 초고마다 관점/구성/문체가 분명히 달라야 함
- 사실 불확실 시 단정하지 말 것

반드시 JSON으로만 응답하세요.
응답 스키마:
{{
  "drafts": [
    {{"title": "...", "markdown": "# ..."}}
  ]
}}
""".strip()

        response = self.client.responses.create(
            model=self.model,
            input=[
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": prompt},
                        {"type": "input_image", "image_url": image_data_url},
                    ],
                }
            ],
            text={"format": {"type": "text"}},
        )

        raw = response.output_text.strip()
        parsed = self._parse_json_object(raw)
        bundle = DraftBundle.model_validate(parsed)

        return DraftBundle(drafts=bundle.drafts[:count])
    @staticmethod
    def _parse_json_object(raw: str) -> dict:
        text = raw.strip()
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
