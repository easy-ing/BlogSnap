import { ChangeEvent, FormEvent, useEffect, useMemo, useState } from "react";

const AUTH_STORAGE_KEY = "blogsnap.auth";

function loadStoredAuth(): { access_token: string; refresh_token: string } | null {
  try {
    const raw = localStorage.getItem(AUTH_STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (typeof parsed?.access_token === "string" && typeof parsed?.refresh_token === "string") {
      return parsed;
    }
    return null;
  } catch {
    return null;
  }
}

function persistAuth(accessToken: string, refreshToken: string) {
  try {
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify({ access_token: accessToken, refresh_token: refreshToken }));
  } catch {
    // best-effort only: e.g. private browsing may block storage
  }
}

function clearStoredAuth() {
  try {
    localStorage.removeItem(AUTH_STORAGE_KEY);
  } catch {
    // ignore
  }
}

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
  error_message?: string | null;
  result_payload?: { publish_job_id?: string };
};

type MeResponse = {
  id: string;
  email: string;
  display_name?: string | null;
  gemini_key_connected: boolean;
  naver_connected: boolean;
};

type Draft = {
  id: string;
  title: string;
  markdown: string;
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

const STATUS_LABEL: Record<string, string> = {
  GENERATED: "생성됨",
  SELECTED: "선택됨",
  ARCHIVED: "보관됨",
};

const STEPS = [
  { no: 1, label: "연결" },
  { no: 2, label: "초고 생성" },
  { no: 3, label: "선택" },
  { no: 4, label: "발행" },
] as const;

function Stepper({
  current,
  unlocked,
  onSelect,
}: {
  current: number;
  unlocked: number;
  onSelect: (step: number) => void;
}) {
  return (
    <ol className="stepper">
      {STEPS.map((step, index) => {
        const isDone = step.no < unlocked;
        const isCurrent = step.no === current;
        const isReachable = step.no <= unlocked;
        return (
          <li key={step.no} className="stepper-item">
            <button
              type="button"
              className={`stepper-node ${isCurrent ? "is-current" : ""} ${isDone ? "is-done" : ""}`}
              onClick={() => isReachable && onSelect(step.no)}
              disabled={!isReachable}
            >
              <span className="stepper-index">{isDone ? "✓" : step.no}</span>
              <span className="stepper-label">{step.label}</span>
            </button>
            {index < STEPS.length - 1 ? <span className={`stepper-line ${isDone ? "is-done" : ""}`} /> : null}
          </li>
        );
      })}
    </ol>
  );
}

const API_BASE = import.meta.env.VITE_API_BASE ?? "/api";

function markdownPreview(markdown: string): string {
  const plain = markdown
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#") && !line.startsWith("-"))
    .join(" ")
    .replace(/[*_`]/g, "")
    .trim();
  return plain.length > 90 ? `${plain.slice(0, 90)}…` : plain;
}

function isBulletList(lines: string[]): boolean {
  return lines.length > 0 && lines.every((line) => /^[-*]\s+/.test(line.trim()));
}

function BulletList({ lines, keyPrefix }: { lines: string[]; keyPrefix: string }) {
  return (
    <ul>
      {lines.map((line, li) => (
        <li key={`${keyPrefix}-${li}`}>{line.trim().replace(/^[-*]\s+/, "")}</li>
      ))}
    </ul>
  );
}

function MarkdownBlock({ markdown }: { markdown: string }) {
  const blocks = markdown.split(/\n{2,}/).map((block) => block.trim()).filter(Boolean);
  return (
    <div className="markdown-body">
      {blocks.map((block, index) => {
        const lines = block.split("\n");
        const headingMatch = lines[0].match(/^(#{1,3})\s+(.*)$/);
        if (headingMatch) {
          const level = headingMatch[1].length;
          const headingText = headingMatch[2];
          const restLines = lines.slice(1).filter((line) => line.trim());
          return (
            <div key={index}>
              {level === 1 ? <h4>{headingText}</h4> : <h5>{headingText}</h5>}
              {restLines.length === 0 ? null : isBulletList(restLines) ? (
                <BulletList lines={restLines} keyPrefix={`${index}-rest`} />
              ) : (
                <p>{restLines.join(" ")}</p>
              )}
            </div>
          );
        }
        if (isBulletList(lines)) {
          return <BulletList key={index} lines={lines} keyPrefix={`${index}`} />;
        }
        return <p key={index}>{block}</p>;
      })}
    </div>
  );
}

export function App() {
  const [email, setEmail] = useState("demo@blogsnap.dev");
  const [displayName, setDisplayName] = useState("BlogSnap Demo");
  const [token, setToken] = useState<string>("");
  const [refreshToken, setRefreshToken] = useState<string>("");

  const [projectName, setProjectName] = useState("내 블로그 프로젝트");
  const [projectId, setProjectId] = useState<string>("");
  const [projects, setProjects] = useState<Project[]>([]);

  const [postType, setPostType] = useState<PostType>("review");
  const [keyword, setKeyword] = useState("아이패드 에어 M3");
  const [sentiment, setSentiment] = useState<SentimentValue>(1);
  const [draftCount, setDraftCount] = useState<2 | 3>(3);
  const [imagePreview, setImagePreview] = useState<string>("");
  const [selectedImageFile, setSelectedImageFile] = useState<File | null>(null);

  const [geminiKeyInput, setGeminiKeyInput] = useState("");
  const [geminiKeyConnected, setGeminiKeyConnected] = useState(false);
  const [naverConnected, setNaverConnected] = useState(false);

  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [selectedDraftId, setSelectedDraftId] = useState<string>("");
  const [expandedDraftId, setExpandedDraftId] = useState<string>("");
  const [publishProvider, setPublishProvider] = useState<"wordpress" | "tistory" | "naver">("wordpress");
  const [publishResult, setPublishResult] = useState<PublishResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("로그인 후 프로젝트를 만들고 초고를 생성하세요.");

  const [currentStep, setCurrentStep] = useState(1);
  const [unlockedStep, setUnlockedStep] = useState(1);

  const goToStep = (step: number) => {
    if (step <= unlockedStep) {
      setCurrentStep(step);
    }
  };
  const advanceTo = (step: number) => {
    setCurrentStep(step);
    setUnlockedStep((prev) => Math.max(prev, step));
  };

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
      persistAuth(data.access_token, data.refresh_token);
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
      persistAuth(auth.access_token, auth.refresh_token);
      setMessage("로그인 완료. 프로젝트를 불러오거나 생성하세요.");
      await loadProjects(auth.access_token);
      await loadMe(auth.access_token);
    } catch (error) {
      setMessage(`로그인 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  // Restore a previous session on load (e.g. after redirecting away to Naver
  // and back — a full browser navigation clears all in-memory state), and
  // surface the ?naver=connected / ?naver=error result of that redirect.
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const naverResult = params.get("naver");
    if (naverResult) {
      window.history.replaceState({}, "", window.location.pathname);
    }

    const stored = loadStoredAuth();
    if (!stored) {
      if (naverResult === "connected") {
        setMessage("네이버 연결은 완료됐지만 로그인 세션이 만료됐어요. 다시 로그인해주세요.");
      } else if (naverResult === "error") {
        setMessage("네이버 연결에 실패했어요. 다시 로그인 후 시도해주세요.");
      }
      return;
    }

    setToken(stored.access_token);
    setRefreshToken(stored.refresh_token);
    (async () => {
      await loadProjects(stored.access_token);
      await loadMe(stored.access_token);
      if (naverResult === "connected") {
        setMessage("네이버 계정 연결 완료. 이제 네이버 블로그에 바로 발행할 수 있어요.");
      } else if (naverResult === "error") {
        setMessage("네이버 연결에 실패했어요. 다시 시도해주세요.");
      } else {
        setMessage("이전 로그인 세션을 복원했어요.");
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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

  const loadMe = async (overrideToken?: string) => {
    try {
      const me = await authedFetch<MeResponse>("/v1/auth/me", {
        headers: overrideToken ? { Authorization: `Bearer ${overrideToken}` } : undefined,
      });
      setGeminiKeyConnected(me.gemini_key_connected);
      setNaverConnected(me.naver_connected);
    } catch {
      // non-critical: leave connected state as-is
    }
  };

  const connectGeminiKey = async () => {
    if (!geminiKeyInput.trim()) {
      setMessage("연결할 Gemini API 키를 입력하세요.");
      return;
    }
    setLoading(true);
    try {
      await authedFetch("/v1/auth/me/gemini-key", {
        method: "PUT",
        body: JSON.stringify({ api_key: geminiKeyInput.trim() }),
      });
      setGeminiKeyConnected(true);
      setGeminiKeyInput("");
      setMessage("Gemini API 키 연결 완료. 이후 초고 생성은 이 키로 진행됩니다.");
    } catch (error) {
      setMessage(`Gemini API 키 연결 실패: ${String(error)}`);
    } finally {
      setLoading(false);
    }
  };

  const disconnectGeminiKey = async () => {
    setLoading(true);
    try {
      await authedFetch("/v1/auth/me/gemini-key", { method: "DELETE" });
      setGeminiKeyConnected(false);
      setMessage("Gemini API 키 연결을 해제했습니다.");
    } catch (error) {
      setMessage(`연결 해제 실패: ${String(error)}`);
    } finally {
      setLoading(false);
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

  const runNextJob = async (pid: string): Promise<Job> => {
    return authedFetch<Job>(`/v1/jobs/run-next?project_id=${pid}`, { method: "POST" });
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
      const job = await runNextJob(projectId);
      if (job.status !== "SUCCEEDED") {
        setMessage(`초고 생성 실패: ${job.error_message ?? job.status}`);
        return;
      }
      const items = await authedFetch<Draft[]>(`/v1/drafts?project_id=${projectId}`);
      setDrafts(items);
      setMessage(`초고 생성 완료: ${items.length}건 확인${imageAssetId ? ` (이미지 연결: ${imageAssetId.slice(0, 8)}...)` : ""}`);
      advanceTo(3);
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
      const job = await runNextJob(projectId);
      if (job.status !== "SUCCEEDED") {
        setMessage(`재생성 실패: ${job.error_message ?? job.status}`);
        return;
      }
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
      advanceTo(4);
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
          provider: publishProvider,
          idempotency_key: crypto.randomUUID(),
        }),
      });
      const publishJobId = job.result_payload?.publish_job_id;
      const ranJob = await runNextJob(projectId);
      if (ranJob.status !== "SUCCEEDED") {
        setMessage(`발행 실패: ${ranJob.error_message ?? ranJob.status}`);
        return;
      }
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

  const connectNaver = async () => {
    setLoading(true);
    try {
      const { login_url } = await authedFetch<{ login_url: string }>("/v1/auth/naver/login-url");
      window.location.href = login_url;
    } catch (error) {
      setMessage(`네이버 연결 실패: ${String(error)}`);
      setLoading(false);
    }
  };

  const disconnectNaver = async () => {
    setLoading(true);
    try {
      await authedFetch("/v1/auth/naver", { method: "DELETE" });
      setNaverConnected(false);
      setMessage("네이버 연결을 해제했습니다.");
    } catch (error) {
      setMessage(`연결 해제 실패: ${String(error)}`);
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

  const canLeaveStep1 = Boolean(token && projectId && geminiKeyConnected);

  return (
    <main className="page">
      <header className="hero">
        <p className="brand-kicker">AI 블로그 자동화</p>
        <h1>BlogSnap</h1>
        <p className="description">사진과 키워드로 블로그 초고를 쓰고, 원하는 곳에 바로 발행하세요.</p>
      </header>

      <Stepper current={currentStep} unlocked={unlockedStep} onSelect={goToStep} />

      {message && currentStep !== 4 ? <p className="status-line">{message}</p> : null}

      {currentStep === 1 && (
        <section className="card">
          <h2>계정 연결</h2>
          <p className="step-desc">로그인하고, 초고 생성에 쓸 Gemini 키와 작업할 프로젝트를 연결하세요.</p>

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

          <div className="connect-box">
            <div className="connect-box-status">
              <span className={`badge ${geminiKeyConnected ? "badge-selected" : "badge-archived"}`}>
                {geminiKeyConnected ? "Gemini API 키 연결됨" : "Gemini API 키 미연결 (필수)"}
              </span>
              <a href="https://aistudio.google.com/apikey" target="_blank" rel="noreferrer" className="btn-link">
                무료 키 발급받기 ↗
              </a>
            </div>
            {geminiKeyConnected ? (
              <button type="button" className="btn-secondary" onClick={disconnectGeminiKey} disabled={loading}>
                연결 해제
              </button>
            ) : (
              <div className="row two">
                <input
                  type="password"
                  placeholder="본인의 Gemini API 키를 입력하세요"
                  value={geminiKeyInput}
                  onChange={(e) => setGeminiKeyInput(e.target.value)}
                />
                <button type="button" onClick={connectGeminiKey} disabled={loading || !token}>
                  키 연결
                </button>
              </div>
            )}
            <p className="connect-box-hint">
              초고 생성은 본인이 연결한 Gemini API 키로만 동작합니다. 한 번 연결하면 다음부터는 다시 입력할 필요 없어요.
            </p>
          </div>

          <div className="connect-box">
            <div className="connect-box-status">
              <span className={`badge ${naverConnected ? "badge-selected" : "badge-archived"}`}>
                {naverConnected ? "네이버 계정 연결됨" : "네이버 계정 미연결 (선택)"}
              </span>
            </div>
            {naverConnected ? (
              <button type="button" className="btn-secondary" onClick={disconnectNaver} disabled={loading}>
                연결 해제
              </button>
            ) : (
              <button type="button" onClick={connectNaver} disabled={loading || !token}>
                네이버로 로그인하고 연결
              </button>
            )}
            <p className="connect-box-hint">
              네이버 블로그에 바로 발행하려면 연결하세요. 나중에 4단계에서 연결해도 됩니다.
            </p>
          </div>

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

          <div className="step-nav">
            <span className="step-nav-hint">
              {canLeaveStep1 ? "다음 단계로 진행할 수 있어요." : "로그인, Gemini 키 연결, 프로젝트 선택을 마쳐야 다음으로 갈 수 있어요."}
            </span>
            <button className="btn-cta" onClick={() => advanceTo(2)} disabled={!canLeaveStep1}>
              다음: 초고 생성
            </button>
          </div>
        </section>
      )}

      {currentStep === 2 && (
        <section className="card">
          <h2>초고 생성</h2>
          <p className="step-desc">키워드와 톤을 정하고, 사진을 첨부하면 AI가 초고 2~3개를 씁니다.</p>

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
            사진 첨부 (선택)
            <input type="file" accept="image/*" onChange={onImageChange} />
          </label>
          {imagePreview ? <img className="preview" src={imagePreview} alt="업로드한 사진 미리보기" /> : null}

          <div className="step-nav">
            <button className="btn-secondary" onClick={() => goToStep(1)}>이전</button>
            <button className="btn-cta" onClick={generateDrafts} disabled={loading || !token}>
              초고 생성 + 작업 실행
            </button>
          </div>
        </section>
      )}

      {currentStep === 3 && (
        <section className="card">
          <h2>초고 선택</h2>
          <p className="step-desc">마음에 드는 초고를 고르거나, 다른 방향으로 다시 써보세요.</p>
          {drafts.length === 0 ? (
            <p className="empty-hint">아직 생성된 초고가 없어요. 이전 단계에서 먼저 초고를 생성해보세요.</p>
          ) : (
            <div className="draft-grid">
              {drafts.map((draft) => {
                const isExpanded = expandedDraftId === draft.id;
                return (
                  <article key={draft.id} className={`draft ${selectedDraftId === draft.id ? "selected" : ""}`}>
                    <div className="draft-head">
                      <h3>{draft.title}</h3>
                      <span className={`badge badge-${draft.status.toLowerCase()}`}>
                        {STATUS_LABEL[draft.status] ?? draft.status}
                      </span>
                    </div>
                    <p className="draft-meta">
                      {POST_TYPE_LABEL[draft.post_type]} · 감정 {draft.sentiment} · v{draft.version_no}-{draft.variant_no}
                    </p>
                    {isExpanded ? (
                      <MarkdownBlock markdown={draft.markdown} />
                    ) : (
                      <p className="draft-preview">{markdownPreview(draft.markdown) || "본문 내용이 비어 있습니다."}</p>
                    )}
                    <button
                      type="button"
                      className="btn-link"
                      onClick={() => setExpandedDraftId(isExpanded ? "" : draft.id)}
                    >
                      {isExpanded ? "본문 접기" : "본문 전체 보기"}
                    </button>
                    <div className="row two">
                      <button onClick={() => selectDraft(draft.id)} disabled={loading}>이 초고 선택</button>
                      <button className="btn-secondary" onClick={() => regenerate(draft.id)} disabled={loading}>다른 방향 재생성</button>
                    </div>
                  </article>
                );
              })}
            </div>
          )}
          <div className="step-nav">
            <button className="btn-secondary" onClick={() => goToStep(2)}>이전</button>
          </div>
        </section>
      )}

      {currentStep === 4 && (
        <section className="card">
          <h2>발행</h2>
          <p className="step-desc">선택한 초고를 원하는 블로그에 바로 올립니다.</p>

          <label>
            발행할 곳
            <select value={publishProvider} onChange={(e) => setPublishProvider(e.target.value as typeof publishProvider)}>
              <option value="wordpress">워드프레스</option>
              <option value="tistory">티스토리</option>
              <option value="naver">네이버 블로그{naverConnected ? "" : " (연결 필요)"}</option>
            </select>
          </label>
          <button className="btn-cta" onClick={publish} disabled={loading || !selectedDraftId}>선택 초고 자동 업로드</button>

          <div className="result-box">
            <strong>결과</strong>
            <p>{message}</p>
            {publishResult ? (
              <pre className="result">{JSON.stringify(publishResult, null, 2)}</pre>
            ) : null}
          </div>

          <div className="step-nav">
            <button className="btn-secondary" onClick={() => goToStep(3)}>이전</button>
            <button className="btn-secondary" onClick={() => advanceTo(2)}>새 초고 만들기</button>
          </div>
        </section>
      )}
    </main>
  );
}
