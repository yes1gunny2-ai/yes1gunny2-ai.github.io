-- HW3 역량 DB 스키마. 런타임은 Node 내장 node:sqlite.
-- 확인되지 않은 값은 NULL로 두고, 화면에서 '확인 필요'로 표시한다.
PRAGMA foreign_keys = ON;

CREATE TABLE projects (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  slug          TEXT NOT NULL UNIQUE,
  title         TEXT NOT NULL,
  subtitle      TEXT NOT NULL,
  period        TEXT,                       -- 기간
  status        TEXT NOT NULL CHECK (status IN ('완료','부분 완료','실험 진행 중','중단·전환','실패·미완성','확인 필요')),  -- 진행 상태
  project_type  TEXT NOT NULL,              -- 프로젝트 유형
  course        TEXT,                       -- 수업명
  team_type     TEXT NOT NULL CHECK (team_type IN ('개인','팀','확인 필요')),
  team_size     INTEGER,                    -- 팀 인원
  role          TEXT,                       -- 본인 역할
  goal          TEXT NOT NULL,              -- 목표
  problem       TEXT NOT NULL,              -- 문제 정의
  method        TEXT NOT NULL,              -- 구현 방법
  results       TEXT NOT NULL,              -- 실험 및 결과
  limitations   TEXT NOT NULL,              -- 한계
  next_steps    TEXT NOT NULL,              -- 개선 방향
  learned       TEXT NOT NULL,              -- 배운 점
  body          TEXT NOT NULL CHECK (length(body) BETWEEN 200 AND 1000),  -- 기술 설명 본문
  github_url    TEXT,                       -- 공개 저장소 URL만 기록
  github_note   TEXT,                       -- 비공개 저장소 안내
  chart_json    TEXT,                       -- 원본에서 옮긴 차트 데이터
  headline      TEXT,                       -- 목록 카드의 핵심 한 줄
  featured      INTEGER NOT NULL DEFAULT 0,
  sort_order    INTEGER NOT NULL DEFAULT 100,
  is_public     INTEGER NOT NULL DEFAULT 1,
  internal_note TEXT,                       -- 공개 내보내기에서 제외
  updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE technologies (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL UNIQUE,
  category    TEXT NOT NULL,
  usage_note  TEXT                         -- 실제 사용 범위 설명
);

CREATE TABLE project_technologies (
  project_id    INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  technology_id INTEGER NOT NULL REFERENCES technologies(id) ON DELETE CASCADE,
  PRIMARY KEY (project_id, technology_id)
);

CREATE TABLE project_job_roles (
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  job_role   TEXT NOT NULL,
  rationale  TEXT,
  PRIMARY KEY (project_id, job_role)
);

-- 수치와 출처 상태. provenance: source=원본 대조, self=본인 기록, check=확인 필요
CREATE TABLE metrics (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id    INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  label         TEXT NOT NULL,
  value         TEXT NOT NULL,
  note          TEXT,
  provenance    TEXT NOT NULL CHECK (provenance IN ('source','self','check')),
  source_ref    TEXT,                      -- 내부 대조 경로. 공개 내보내기에서 제외
  is_public     INTEGER NOT NULL DEFAULT 1,
  sort_order    INTEGER NOT NULL DEFAULT 100,
  CHECK (NOT (provenance = 'check' AND is_public = 1))  -- 확인 전 수치는 공개 금지
);

-- 구현·검증 범위. state: verified/implemented/design/not_run
CREATE TABLE scope_items (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  item       TEXT NOT NULL,
  state      TEXT NOT NULL CHECK (state IN ('verified','implemented','design','not_run')),
  sort_order INTEGER NOT NULL DEFAULT 100
);

-- 증빙. access: public=파일/링크 공개, private=비공개 보관, missing=원본 미확인
CREATE TABLE evidence (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id    INTEGER REFERENCES projects(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  kind          TEXT NOT NULL CHECK (kind IN ('이미지','보고서','코드','데이터','링크','발표자료')),
  access        TEXT NOT NULL CHECK (access IN ('public','private','missing')),
  url           TEXT,                      -- public일 때 사이트 내 경로 또는 외부 URL
  description   TEXT NOT NULL,
  internal_note TEXT,                      -- 공개 내보내기에서 제외
  sort_order    INTEGER NOT NULL DEFAULT 100,
  CHECK (access <> 'public' OR url IS NOT NULL)
);

-- 글로벌·기타 역량. status: verified=문서 확인, self=본인 기록, goal=목표(미취득), none=해당 없음
CREATE TABLE capabilities (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  slug          TEXT NOT NULL UNIQUE,
  category      TEXT NOT NULL,
  title         TEXT NOT NULL,
  value         TEXT,
  description   TEXT NOT NULL,
  status        TEXT NOT NULL CHECK (status IN ('verified','self','goal','none')),
  is_public     INTEGER NOT NULL DEFAULT 1,
  internal_note TEXT,
  sort_order    INTEGER NOT NULL DEFAULT 100
);

CREATE TABLE capability_projects (
  capability_id INTEGER NOT NULL REFERENCES capabilities(id) ON DELETE CASCADE,
  project_id    INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  PRIMARY KEY (capability_id, project_id)
);

CREATE TABLE capability_evidence (
  capability_id INTEGER NOT NULL REFERENCES capabilities(id) ON DELETE CASCADE,
  evidence_id   INTEGER NOT NULL REFERENCES evidence(id) ON DELETE CASCADE,
  PRIMARY KEY (capability_id, evidence_id)
);

-- 직무 역량과 프로젝트 연결 (Career Fit)
CREATE TABLE competencies (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  slug        TEXT NOT NULL UNIQUE,
  job_track   TEXT NOT NULL CHECK (job_track IN ('공정기술','장비 CS','공통')),
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  sort_order  INTEGER NOT NULL DEFAULT 100
);

CREATE TABLE competency_projects (
  competency_id INTEGER NOT NULL REFERENCES competencies(id) ON DELETE CASCADE,
  project_id    INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  evidence_text TEXT NOT NULL,
  PRIMARY KEY (competency_id, project_id)
);

-- 기업 분석 과제 연결
CREATE TABLE companies (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  slug            TEXT NOT NULL UNIQUE,
  name            TEXT NOT NULL,
  target_role     TEXT NOT NULL,
  analysis_status TEXT NOT NULL CHECK (analysis_status IN ('완료','예정')),
  summary         TEXT,
  sort_order      INTEGER NOT NULL DEFAULT 100
);

CREATE TABLE company_projects (
  company_id INTEGER NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  rationale  TEXT NOT NULL,
  PRIMARY KEY (company_id, project_id)
);

-- 관리 화면 변경 이력
CREATE TABLE audit_log (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  row_id     INTEGER,
  action     TEXT NOT NULL,
  changed_at TEXT NOT NULL DEFAULT (datetime('now'))
);
