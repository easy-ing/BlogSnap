# Day 20 실행 계획 (2026-04-23)

## 목표
- 생성된 초고(2~3안)에 대해 품질 점수를 계산하고 추천안을 제공한다.
- 사용자가 빠르게 선택할 수 있도록 추천 근거를 API 응답으로 제공한다.

## 오늘 할 일
1. [x] 초고 품질 평가 로직(키워드/길이/구조/감정톤) 구현
2. [x] 추천 API `GET /v1/drafts/recommend` 추가
3. [x] Day20 데모 스크립트 추가
4. [x] Day20 테스트 추가
5. [x] README/Backend README/로드맵 업데이트

## 산출물
- [backend/app/services/draft_quality.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/services/draft_quality.py)
- [backend/app/api/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/api/drafts.py)
- [backend/app/schemas/drafts.py](/Users/jin/Desktop/easy_ing/BlogSnap/backend/app/schemas/drafts.py)
- [scripts/day20_quality_recommend_demo.sh](/Users/jin/Desktop/easy_ing/BlogSnap/scripts/day20_quality_recommend_demo.sh)
- [tests/test_draft_recommendation.py](/Users/jin/Desktop/easy_ing/BlogSnap/tests/test_draft_recommendation.py)

## 메모
- Day20 점수는 MVP용 휴리스틱이며, 추후 LLM 평가/실제 성과 지표(CTR, 체류시간)로 확장 가능하다.
