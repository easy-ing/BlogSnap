import { ChangeEvent, FormEvent, useMemo, useState } from "react";

type PostType = "review" | "explanation" | "impression";
type SentimentValue = -2 | -1 | 0 | 1 | 2;

type LoginResponse = {
  access_token: string;
  refresh_token: string;
  token_type: string;
};

type Project = {
  id: string;
  name: string;
};

type Job = {
  id: string;
  status: string;
  result_payload?: { publish_job_id?: string };
};

type Draft = {
  id: string;
  title: string;
  keyword: string;
  post_type: PostType;
  sentiment: number;
  version_no: number;
  variant_no: number;
  status: string;
};

type PublishResult = {
  id: string;
  status: string;
  post_url?: string | null;
  schedule_status: string;
  error_message?: string | null;
};

type Asset = {
  id: string;
  project_id: string;
  source_filename?: string | null;
  content_type: string;
  byte_size: number;
  url?: string | null;
  status: string;
};

const SENTIMENT_OPTIONS: { value: SentimentValue; label: string; example: string }[] = [
  { value: -2, label: "매우 부정", example: "문제점 위주로 냉정하게 분석합니다." },
  { value: -1, label: "약간 부정", example: "아쉬운 점을 중심으로 균형 있게 작성합니다." },
  { value: 0, label: "중립", example: "정보 전달 위주로 담백하게 씁니다." },
  { value: 1, label: "약간 긍정", example: "장점 중심이지만 단점도 간단히 언급합니다." },
  { value: 2, label: "매우 긍정", example: "추천하는 톤으로 강하게 호평합니다." },
];

const POST_TYPE_LABEL: Record<PostType, string> = {
  review: "리뷰",
  explanation: "설명",
  impression: "소감문",
};

const API_BASE = import.meta.env.VITE_API_BASE ?? "/api";

export function App() {
  const [email, setEmail] = useState("demo@blogsnap.dev");
  const [displayName, setDisplayName] = useState("BlogSnap Demo");
  const [token, setToken] = useState<string>("");
  const [refreshToken, setRefreshToken] = useState<string>("");

  const [projectName, setProjectName] = useState("Day27 Frontend Demo");
  const [projectId, setProjectId] = useState<string>("");
  const [projects, setProjects] = useState<Project[]>([]);

  const [postType, setPostType] = useState<PostType>("review");
  const [keyword, setKeyword] = useState("아이패드 에어 M3");
  const [sentiment, setSentiment] = useState<SentimentValue>(1);
  const [draftCount, setDraftCount] = useState<2 | 3>(3);
  const [imagePreview, setImagePreview] = useState<string>("");
  const [selectedImageFile, setSelectedImageFile] = useState<File | null>(null);

  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [selectedDraftId, setSelectedDraftId] = useState<string>("");
  const [publishResult, setPublishResult] = useState<PublishResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("로그인 후 프로젝트를 만들고 초고를 생성하세요.");

  const sentimentExample = useMemo(
    () => SENTIMENT_OPTIONS.find((item) => item.value === sentiment)?.example ?? "",
    [sentiment]
  );

  const authedFetch = async <T,>(path: string, init?: RequestInit): Promise<T> => {
    const headers = new Headers(init?.headers ?? {});
    headers.set("Content-Type", "application/json");
    if (token) {
      headers.set("Authorization", `Bearer ${token}`);
    }

    const response = await fetch(`${API_BASE}${path}`, {
      ...init,
      headers,
    });

    if (response.status === 401 && refreshToken) {
      const refreshed = await refreshAuth();
      if (refreshed) {
        const retryHeaders = new Headers(init?.headers ?? {});
        retryHeaders.set("Content-Type", "application/json");
        retryHeaders.set("Authorization", `Bearer ${refreshed.access_token}`);
        const retryResponse = await fetch(`${API_BASE}${path}`, {
          ...init,
          headers: retryHeaders,
        });
        if (!retryResponse.ok) {
          throw new Error(await retryResponse.text());
        }
        return (await retryResponse.json()) as T;
      }
    }

    if (!response.ok) {
      throw new Error(await response.text());
    }

    return (await response.json()) as T;
  };

  const refreshAuth = async (): Promise<LoginResponse | null> => {
    if (!refreshToken) {
      return null;
    }
    try {
      const response = await fetch(`${API_BASE}/v1/auth/refresh`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh_token: refreshToken }),
      });
      if (!response.ok) {
        return null;
      }
      const data = (await response.json()) as LoginResponse;
      setToken(data.access_token);
      setRefreshToken(data.refresh_token);
      return data;
    } catch {
      return null;
    }
  };

  const login = async () => {
    setLoading(true);
    try {
      const data = await fetch(`${API_BASE}/v1/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, display_name: displayName }),
      });
      if (!data.ok) {
        throw new Error(await data.text());
      }
      const auth = (await data.json()) as LoginResponse;
      setToken(auth.access_token);
      setRefreshToken(auth.refresh_token);
      setMessage("로그인 완료. 프로젝트를 불러오거나 생성하세요.");
      await loadProjects(auth.access_token);
    } catch (error) {
      setMessage(`로그인 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const loadProjects = async (overrideToken?: string) => {
    try {
      const list = await authedFetch<Project[]>("/v1/projects", {
        headers: overrideToken ? { Authorization: `Bearer ${overrideToken}` } : undefined,
      });
      setProjects(list);
      if (!projectId && list[0]) {
        setProjectId(list[0].id);
      }
    } catch (error) {
      setMessage(`프로젝트 조회 실패: ${String(error)}`);
    }
  };

  const createProject = async (event: FormEvent) => {
    event.preventDefault();
    setLoading(true);
    try {
      const created = await authedFetch<Project>("/v1/projects", {
        method: "POST",
        body: JSON.stringify({ name: projectName }),
      });
      setProjectId(created.id);
      setProjects((prev) => [created, ...prev]);
      setMessage(`프로젝트 생성 완료: ${created.name}`);
    } catch (error) {
      setMessage(`프로젝트 생성 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const runNextJob = async (pid: string) => {
    await authedFetch<Job>(`/v1/jobs/run-next?project_id=${pid}`, { method: "POST" });
  };

  const generateDrafts = async () => {
    if (!projectId) {
      setMessage("먼저 프로젝트를 선택하세요.");
      return;
    }
    setLoading(true);
    try {
      let imageAssetId: string | undefined;
      if (selectedImageFile) {
        const form = new FormData();
        form.append("project_id", projectId);
        form.append("file", selectedImageFile);

        const uploadResp = await fetch(`${API_BASE}/v1/assets/upload`, {
          method: "POST",
          headers: token ? { Authorization: `Bearer ${token}` } : undefined,
          body: form,
        });
        if (!uploadResp.ok) {
          throw new Error(await uploadResp.text());
        }
        const uploaded = (await uploadResp.json()) as Asset;
        imageAssetId = uploaded.id;
      }

      await authedFetch<Job>("/v1/drafts/generate", {
        method: "POST",
        body: JSON.stringify({
          project_id: projectId,
          post_type: postType,
          keyword,
          sentiment,
          image_asset_id: imageAssetId,
          draft_count: draftCount,
          idempotency_key: crypto.randomUUID(),
        }),
      });
      await runNextJob(projectId);
      const items = await authedFetch<Draft[]>(`/v1/drafts?project_id=${projectId}`);
      setDrafts(items);
      setMessage(`초고 생성 완료: ${items.length}건 확인${imageAssetId ? ` (이미지 연결: ${imageAssetId.slice(0, 8)}...)` : ""}`);
    } catch (error) {
      setMessage(`초고 생성 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const regenerate = async (draftId: string) => {
    if (!projectId) {
      return;
    }
    setLoading(true);
    try {
      await authedFetch<Job>(`/v1/drafts/${draftId}/regenerate`, {
        method: "POST",
        body: JSON.stringify({ idempotency_key: crypto.randomUUID() }),
      });
      await runNextJob(projectId);
      const items = await authedFetch<Draft[]>(`/v1/drafts?project_id=${projectId}`);
      setDrafts(items);
      setMessage("다른 방향성으로 재생성 완료");
    } catch (error) {
      setMessage(`재생성 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const selectDraft = async (draftId: string) => {
    setLoading(true);
    try {
      await authedFetch<Draft>(`/v1/drafts/${draftId}/select`, { method: "POST" });
      setSelectedDraftId(draftId);
      const items = await authedFetch<Draft[]>(`/v1/drafts?project_id=${projectId}`);
      setDrafts(items);
      setMessage("초고 선택 완료");
    } catch (error) {
      setMessage(`선택 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const publish = async () => {
    if (!projectId || !selectedDraftId) {
      setMessage("선택된 초고가 필요합니다.");
      return;
    }
    setLoading(true);
    try {
      const job = await authedFetch<Job>("/v1/publish", {
        method: "POST",
        body: JSON.stringify({
          project_id: projectId,
          draft_id: selectedDraftId,
          provider: "wordpress",
          idempotency_key: crypto.randomUUID(),
        }),
      });
      await runNextJob(projectId);
      const publishJobId = job.result_payload?.publish_job_id;
      if (!publishJobId) {
        throw new Error("publish_job_id not found");
      }
      const result = await authedFetch<PublishResult>(`/v1/publish/${publishJobId}`);
      setPublishResult(result);
      setMessage("발행 처리 완료");
    } catch (error) {
      setMessage(`발행 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const onImageChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) {
      setImagePreview("");
      setSelectedImageFile(null);
      return;
    }
    const url = URL.createObjectURL(file);
    setImagePreview(url);
    setSelectedImageFile(file);
  };

  return (
    <main className="page">
      <section className="card">
        <h1>BlogSnap Day27 Frontend</h1>
        <p className="description">글 유형 선택 -&gt; 키워드/이미지/긍부정 설정 -&gt; 초고 2~3개 생성 -&gt; 선택 -&gt; 자동 발행</p>

        <div className="row two">
          <label>
            이메일
            <input value={email} onChange={(e) => setEmail(e.target.value)} />
          </label>
          <label>
            닉네임
            <input value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
          </label>
        </div>
        <button onClick={login} disabled={loading}>로그인</button>

        <form onSubmit={createProject} className="stack">
          <div className="row two">
            <label>
              새 프로젝트명
              <input value={projectName} onChange={(e) => setProjectName(e.target.value)} />
            </label>
            <label>
              기존 프로젝트
              <select value={projectId} onChange={(e) => setProjectId(e.target.value)}>
                <option value="">선택하세요</option>
                {projects.map((project) => (
                  <option key={project.id} value={project.id}>{project.name}</option>
                ))}
              </select>
            </label>
          </div>
          <button type="submit" disabled={loading || !token}>프로젝트 생성</button>
        </form>
      </section>

      <section className="card">
        <h2>초고 생성</h2>
        <div className="row three">
          <label>
            글 종류
            <select value={postType} onChange={(e) => setPostType(e.target.value as PostType)}>
              <option value="review">리뷰</option>
              <option value="explanation">설명</option>
              <option value="impression">소감문</option>
            </select>
          </label>
          <label>
            키워드
            <input value={keyword} onChange={(e) => setKeyword(e.target.value)} />
          </label>
          <label>
            초고 개수
            <select value={draftCount} onChange={(e) => setDraftCount(Number(e.target.value) as 2 | 3)}>
              <option value={2}>2개</option>
              <option value={3}>3개</option>
            </select>
          </label>
        </div>

        <div className="row two">
          <label>
            긍부정 정도
            <select value={sentiment} onChange={(e) => setSentiment(Number(e.target.value) as SentimentValue)}>
              {SENTIMENT_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>{option.label}</option>
              ))}
            </select>
          </label>
          <div className="hint-box">
            <strong>예시 문장</strong>
            <p>{sentimentExample}</p>
          </div>
        </div>

        <label>
          사진 첨부 (Day27: 업로드 후 초고 생성에 연결)
          <input type="file" accept="image/*" onChange={onImageChange} />
        </label>
        {imagePreview ? <img className="preview" src={imagePreview} alt="preview" /> : null}

        <button onClick={generateDrafts} disabled={loading || !token}>초고 생성 + 작업 실행</button>
      </section>

      <section className="card">
        <h2>초고 목록</h2>
        <div className="draft-grid">
          {drafts.map((draft) => (
            <article key={draft.id} className={`draft ${selectedDraftId === draft.id ? "selected" : ""}`}>
              <h3>{draft.title}</h3>
              <p>{POST_TYPE_LABEL[draft.post_type]} / 감정 {draft.sentiment} / v{draft.version_no}-{draft.variant_no}</p>
              <p>상태: {draft.status}</p>
              <div className="row two">
                <button onClick={() => selectDraft(draft.id)} disabled={loading}>이 초고 선택</button>
                <button onClick={() => regenerate(draft.id)} disabled={loading}>다른 방향 재생성</button>
              </div>
            </article>
          ))}
        </div>
        <button onClick={publish} disabled={loading || !selectedDraftId}>선택 초고 자동 업로드</button>
      </section>

      <section className="card">
        <h2>결과</h2>
        <p>{message}</p>
        {publishResult ? (
          <pre className="result">{JSON.stringify(publishResult, null, 2)}</pre>
        ) : null}
      </section>
    </main>
  );
}
