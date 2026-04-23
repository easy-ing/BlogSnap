from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from backend.app.models.entities import Draft


POSITIVE_TOKENS = ("좋", "추천", "만족", "유용", "효율", "장점")
NEGATIVE_TOKENS = ("아쉽", "불편", "문제", "단점", "부족", "비추천")


@dataclass
class ScoredDraft:
    draft: Draft
    score: float
    reasons: list[str]


def _count_keyword_hits(text: str, keyword: str) -> int:
    if not keyword:
        return 0
    return text.count(keyword.lower())


def _token_hits(text: str, tokens: Iterable[str]) -> int:
    return sum(text.count(token) for token in tokens)


def score_draft(draft: Draft) -> tuple[float, list[str]]:
    text = f"{draft.title}\n{draft.markdown}"
    lowered = text.lower()
    reasons: list[str] = []
    score = 0.0

    # 1) Keyword reflection (max 40)
    keyword_hits = _count_keyword_hits(lowered, draft.keyword.lower())
    keyword_score = min(40.0, float(keyword_hits * 12))
    if keyword_hits >= 2:
        reasons.append("키워드 반영률이 높습니다.")
    elif keyword_hits == 1:
        reasons.append("키워드가 본문에 반영되었습니다.")
    else:
        reasons.append("키워드 반영률을 더 높일 수 있습니다.")
    score += keyword_score

    # 2) Length quality (max 30)
    length = len(draft.markdown.strip())
    if 280 <= length <= 1200:
        length_score = 30.0
        reasons.append("본문 길이가 발행에 적절합니다.")
    elif 180 <= length < 280 or 1200 < length <= 1800:
        length_score = 20.0
        reasons.append("본문 길이가 다소 짧거나 길지만 허용 범위입니다.")
    elif 80 <= length < 180:
        length_score = 10.0
        reasons.append("본문 길이가 짧아 보강 여지가 있습니다.")
    else:
        length_score = 5.0
        reasons.append("본문 길이를 권장 범위로 조정하는 것이 좋습니다.")
    score += length_score

    # 3) Structure quality (max 15)
    heading_count = sum(1 for line in draft.markdown.splitlines() if line.startswith("## "))
    if heading_count >= 2:
        structure_score = 15.0
        reasons.append("문단 구조(헤딩)가 잘 구성되어 있습니다.")
    elif heading_count == 1:
        structure_score = 10.0
        reasons.append("기본 문단 구조는 있으나 세부 구성이 더 필요합니다.")
    else:
        structure_score = 5.0
        reasons.append("헤딩 구조를 추가하면 가독성이 좋아집니다.")
    score += structure_score

    # 4) Sentiment tone alignment (max 15)
    pos_hits = _token_hits(draft.markdown, POSITIVE_TOKENS)
    neg_hits = _token_hits(draft.markdown, NEGATIVE_TOKENS)
    if draft.sentiment > 0:
        sentiment_score = 15.0 if pos_hits >= neg_hits else 6.0
    elif draft.sentiment < 0:
        sentiment_score = 15.0 if neg_hits >= pos_hits else 6.0
    else:
        sentiment_score = 15.0 if abs(pos_hits - neg_hits) <= 1 else 8.0
    score += sentiment_score

    if sentiment_score >= 12:
        reasons.append("감정 톤이 요청값과 대체로 일치합니다.")
    else:
        reasons.append("감정 톤 정합성을 보완할 수 있습니다.")

    return round(max(0.0, min(100.0, score)), 1), reasons


def rank_drafts(drafts: list[Draft]) -> list[ScoredDraft]:
    scored: list[ScoredDraft] = []
    for draft in drafts:
        score, reasons = score_draft(draft)
        scored.append(ScoredDraft(draft=draft, score=score, reasons=reasons))
    scored.sort(key=lambda item: (-item.score, item.draft.variant_no, item.draft.created_at))
    return scored
