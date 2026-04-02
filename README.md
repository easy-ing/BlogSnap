# BlogSnap

BlogSnap은 `키워드 + 사진 + 감정 강도`를 기반으로 블로그 초고를 2~3개 생성하고, 사용자가 선택한 초고를 자동 업로드하는 프로젝트입니다.

## Day 1 완료 기록 (2026-04-02)
오늘은 **요구사항 정의(PRD v1) + 동작하는 MVP 구현**까지 완료했습니다.

### Day 1 문제 정의
- 블로그 작성/업로드가 반복적이고 번거롭다.
- 최소 입력으로 글 생성부터 게시까지 자동화가 필요하다.

### Day 1 핵심 사용자 플로우
1. 글 종류 선택 (`리뷰 / 설명형 / 소감문`)
2. 키워드 입력
3. 사진 업로드
4. 긍정/부정 강도 선택 (`-2 ~ +2`) + 예시 가이드 확인
5. 초고 2~3개 생성
6. 마음에 드는 초고 선택
7. 선택 초고 자동 업로드

### Day 1 범위 확정
`In Scope`
- 글 종류 선택
- 감정 강도 기반 톤 제어
- 초고 2~3개 생성
- 초고 재생성
- 선택 초고 자동 업로드(WordPress)

`Out of Scope`
- 멀티 사용자 인증/권한
- 백엔드 서버 분리(FastAPI)
- DB 영속 저장
- 예약 발행/큐/재시도
- 티스토리/네이버 연동

### Day 1 완료 기준(DoD)
- 요구사항 문서화 완료
- 필수/제외 기능 분리 완료
- MVP 성공 시나리오 정의 완료
- Day 2 착수 조건 명확화 완료

## 현재 MVP 구현 상태
- Streamlit UI 플로우 구현
- OpenAI 기반 초고 2~3개 생성
- 다른 방향성으로 재생성 가능
- 선택 초고 WordPress 자동 업로드
- 이미지 미디어 업로드 + 대표 이미지 설정

## 실행 방법
### 1) 설치
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2) 환경 변수
```bash
cp .env.example .env
```

`.env` 항목:
- `OPENAI_API_KEY`
- `OPENAI_MODEL` (예: `gpt-5-mini`)
- `BLOG_PROVIDER=wordpress`
- `BLOG_BASE_URL`
- `BLOG_USERNAME`
- `BLOG_APP_PASSWORD`
- `DEFAULT_TAGS`

### 3) 앱 실행
```bash
streamlit run app.py
```

## 브랜치 운영 전략
- `main`: 항상 배포 가능한 안정 브랜치
- `develop`: 통합 작업 브랜치
- 기능 브랜치: `codex/feat/...`, `codex/chore/...`, `codex/fix/...`

추천 규칙:
1. PR 하나 = 목적 하나
2. PR은 작게 유지(가능하면 300줄 내외)
3. 머지 대상은 기본적으로 `develop`
4. `main`은 릴리즈/핫픽스만 머지

## PR 템플릿
- 기본 템플릿: [.github/pull_request_template.md](/Users/jin/Desktop/easy_ing/BlogSnap/.github/pull_request_template.md)

## 주요 파일
- [app.py](/Users/jin/Desktop/easy_ing/BlogSnap/app.py): UI 기반 생성/선택/업로드
- [main.py](/Users/jin/Desktop/easy_ing/BlogSnap/main.py): CLI 진입점
- [blogsnap/ai_writer.py](/Users/jin/Desktop/easy_ing/BlogSnap/blogsnap/ai_writer.py): 초고 생성 로직
- [blogsnap/blog_clients/wordpress.py](/Users/jin/Desktop/easy_ing/BlogSnap/blogsnap/blog_clients/wordpress.py): WordPress 업로드
- [blogsnap/pipeline.py](/Users/jin/Desktop/easy_ing/BlogSnap/blogsnap/pipeline.py): CLI 파이프라인

## 다음 챕터
- **Day 2: 시스템 아키텍처 설계**
- 목표: 프론트/백엔드/비동기 작업/DB 경계 정의
