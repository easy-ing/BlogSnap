-- BlogSnap initial schema (PostgreSQL)
-- Requires: pgcrypto extension for gen_random_uuid()

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enums
CREATE TYPE post_type AS ENUM ('review', 'explanation', 'impression');
CREATE TYPE job_type AS ENUM ('draft_generate', 'draft_regenerate', 'publish');
CREATE TYPE job_status AS ENUM ('PENDING', 'RUNNING', 'SUCCEEDED', 'FAILED', 'RETRYING');
CREATE TYPE draft_status AS ENUM ('GENERATED', 'SELECTED', 'ARCHIVED');
CREATE TYPE publish_status AS ENUM ('REQUESTED', 'PUBLISHED', 'ERROR');
CREATE TYPE schedule_status AS ENUM ('READY', 'SCHEDULED', 'CANCELLED');
CREATE TYPE provider_type AS ENUM ('wordpress', 'tistory');
CREATE TYPE asset_status AS ENUM ('UPLOADED', 'AVAILABLE', 'DELETED', 'ERROR');

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Projects
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  default_provider provider_type NOT NULL DEFAULT 'wordpress',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Assets
CREATE TABLE assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  storage_key TEXT NOT NULL,
  source_filename TEXT,
  content_type TEXT NOT NULL,
  byte_size BIGINT NOT NULL CHECK (byte_size > 0),
  url TEXT,
  status asset_status NOT NULL DEFAULT 'UPLOADED',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (project_id, storage_key)
);

-- Unified Jobs table
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  type job_type NOT NULL,
  status job_status NOT NULL DEFAULT 'PENDING',
  idempotency_key TEXT,
  request_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  result_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_code TEXT,
  error_message TEXT,
  attempt_count INT NOT NULL DEFAULT 0,
  max_attempts INT NOT NULL DEFAULT 3,
  next_retry_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT jobs_attempt_non_negative CHECK (attempt_count >= 0),
  CONSTRAINT jobs_max_attempts_positive CHECK (max_attempts > 0),
  CONSTRAINT jobs_idempotency_unique UNIQUE (project_id, type, idempotency_key)
);

-- Drafts
CREATE TABLE drafts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  source_job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
  post_type post_type NOT NULL,
  keyword TEXT NOT NULL,
  sentiment SMALLINT NOT NULL CHECK (sentiment BETWEEN -2 AND 2),
  title TEXT NOT NULL,
  markdown TEXT NOT NULL,
  version_no INT NOT NULL DEFAULT 1,
  variant_no SMALLINT NOT NULL CHECK (variant_no BETWEEN 1 AND 3),
  status draft_status NOT NULL DEFAULT 'GENERATED',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (project_id, version_no, variant_no)
);

-- Publish jobs
CREATE TABLE publish_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  draft_id UUID NOT NULL REFERENCES drafts(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
  provider provider_type NOT NULL DEFAULT 'wordpress',
  status publish_status NOT NULL DEFAULT 'REQUESTED',
  external_post_id TEXT,
  post_url TEXT,
  request_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  response_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  schedule_status schedule_status NOT NULL DEFAULT 'READY',
  scheduled_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Publish logs
CREATE TABLE publish_logs (
  id BIGSERIAL PRIMARY KEY,
  publish_job_id UUID NOT NULL REFERENCES publish_jobs(id) ON DELETE CASCADE,
  level TEXT NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Provider tokens (encrypted value managed by app layer or KMS)
CREATE TABLE provider_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider provider_type NOT NULL,
  encrypted_access_token TEXT NOT NULL,
  encrypted_refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, provider)
);

-- Auth sessions (refresh token lifecycle)
CREATE TABLE auth_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE INDEX idx_assets_project_created_at ON assets(project_id, created_at DESC);

CREATE INDEX idx_jobs_project_type_status_created_at
  ON jobs(project_id, type, status, created_at DESC);
CREATE INDEX idx_jobs_status_next_retry_at
  ON jobs(status, next_retry_at)
  WHERE status IN ('PENDING', 'RETRYING');
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);

CREATE INDEX idx_drafts_project_status_created_at
  ON drafts(project_id, status, created_at DESC);
CREATE INDEX idx_drafts_keyword_gin
  ON drafts USING gin (to_tsvector('simple', keyword));

CREATE INDEX idx_publish_jobs_project_status_created_at
  ON publish_jobs(project_id, status, created_at DESC);
CREATE INDEX idx_publish_jobs_draft_id ON publish_jobs(draft_id);
CREATE INDEX idx_publish_logs_publish_job_id_created_at
  ON publish_logs(publish_job_id, created_at DESC);
CREATE INDEX idx_auth_sessions_user_expires_at ON auth_sessions(user_id, expires_at DESC);
