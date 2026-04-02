import uuid
from pathlib import Path

import streamlit as st

from blogsnap.ai_writer import AIWriter
from blogsnap.blog_clients.wordpress import WordPressClient
from blogsnap.config import load_settings
from blogsnap.schemas import DraftRequest


st.set_page_config(page_title="BlogSnap", layout="wide")
st.title("BlogSnap 자동 블로그 작성기")
st.caption("글 유형 선택 → 키워드/사진 입력 → 감정 강도 설정 → 초고 선택 후 자동 업로드")

settings = load_settings()

if "drafts" not in st.session_state:
    st.session_state["drafts"] = []
if "uploaded_image_path" not in st.session_state:
    st.session_state["uploaded_image_path"] = ""
if "selected_index" not in st.session_state:
    st.session_state["selected_index"] = 0

post_type_map = {
    "리뷰": "review",
    "설명형": "explanation",
    "소감문": "impression",
}

left, right = st.columns([1, 1])

with left:
    st.subheader("1) 글 방향 설정")
    post_type_label = st.selectbox("글 종류", ["리뷰", "설명형", "소감문"], index=0)

    st.subheader("2) 입력 데이터")
    keyword = st.text_input("핵심 키워드", placeholder="예: 생산성 자동화")
    cta = st.text_input("마무리 문구(선택)", placeholder="예: 여러분의 루틴도 댓글로 공유해주세요")
    uploaded_image = st.file_uploader(
        "사진 업로드",
        type=["png", "jpg", "jpeg", "webp"],
        accept_multiple_files=False,
    )

with right:
    st.subheader("3) 긍정/부정 강도")
    sentiment = st.slider(
        "감정 강도",
        min_value=-2,
        max_value=2,
        value=0,
        help="-2(강한 부정) ~ +2(강한 긍정)",
    )

    with st.expander("예시 보기 (긍정/부정 가이드)", expanded=False):
        st.markdown(
            """
- `+2 강한 긍정`: "강력 추천합니다", "확실히 만족스러웠습니다"
- `+1 약한 긍정`: "전반적으로 괜찮았습니다", "무난하게 만족"
- `0 중립`: "장단점이 공존합니다", "상황에 따라 다릅니다"
- `-1 약한 부정`: "아쉬운 점이 있습니다", "개선이 필요해 보입니다"
- `-2 강한 부정`: "추천하기 어렵습니다", "핵심 문제가 큽니다"
            """
        )

    draft_count = st.radio("초고 개수", options=[2, 3], horizontal=True, index=1)

st.divider()

col_a, col_b = st.columns([1, 1])
with col_a:
    generate_btn = st.button("초고 생성", type="primary", use_container_width=True)
with col_b:
    regen_label = st.selectbox("다른 방향성으로 재생성", ["리뷰", "설명형", "소감문"], index=0)
    regen_btn = st.button("재생성 실행", use_container_width=True)


def save_uploaded_file() -> str:
    if uploaded_image is None:
        raise ValueError("사진을 업로드해 주세요.")

    upload_dir = Path(".tmp_uploads")
    upload_dir.mkdir(parents=True, exist_ok=True)
    file_path = upload_dir / f"{uuid.uuid4().hex}_{uploaded_image.name}"
    file_path.write_bytes(uploaded_image.getbuffer())
    return str(file_path.resolve())


def generate(post_type_label_value: str) -> None:
    if not keyword.strip():
        st.error("키워드를 입력해 주세요.")
        return

    try:
        image_path = save_uploaded_file()
        st.session_state["uploaded_image_path"] = image_path

        req = DraftRequest(
            post_type=post_type_map[post_type_label_value],
            keyword=keyword.strip(),
            image_path=image_path,
            sentiment=sentiment,
            cta=cta.strip() or None,
        )

        writer = AIWriter(api_key=settings.openai_api_key, model=settings.openai_model)
        with st.spinner("초고를 생성하고 있어요..."):
            bundle = writer.generate_drafts(req, count=draft_count)

        st.session_state["drafts"] = [item.model_dump() for item in bundle.drafts]
        st.session_state["selected_index"] = 0
        st.success(f"초고 {len(bundle.drafts)}개를 만들었습니다.")
    except Exception as e:
        st.error(f"초고 생성 중 오류: {e}")


if generate_btn:
    generate(post_type_label)

if regen_btn:
    generate(regen_label)


drafts = st.session_state.get("drafts", [])
if drafts:
    st.subheader("4) 초고 선택")
    options = [f"초고 {i + 1}: {d['title']}" for i, d in enumerate(drafts)]
    selected = st.radio("업로드할 초고를 선택하세요", options=range(len(options)), format_func=lambda i: options[i])
    st.session_state["selected_index"] = selected

    selected_draft = drafts[selected]
    st.markdown("### 선택한 초고 미리보기")
    st.markdown(selected_draft["markdown"])

    if st.button("선택한 초고 자동 업로드", type="primary"):
        try:
            client = WordPressClient(
                base_url=settings.blog_base_url,
                username=settings.blog_username,
                app_password=settings.blog_app_password,
            )
            with st.spinner("워드프레스에 업로드 중..."):
                url = client.upload_post(
                    title=selected_draft["title"],
                    markdown=selected_draft["markdown"],
                    image_path=st.session_state["uploaded_image_path"],
                    tags=settings.default_tags,
                    category=settings.default_category,
                )

            st.success("업로드 완료")
            if url:
                st.markdown(f"게시글 링크: [{url}]({url})")
        except Exception as e:
            st.error(f"업로드 중 오류: {e}")
else:
    st.info("초고를 먼저 생성해 주세요.")
