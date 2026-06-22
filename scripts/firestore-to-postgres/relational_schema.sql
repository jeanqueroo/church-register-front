-- Esquema relacional (tablas reales en public).
-- Los datos se cargan con: npm run normalize

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Utilidades para leer JSON migrado desde Firestore
CREATE OR REPLACE FUNCTION public.fs_text(j JSONB)
RETURNS TEXT LANGUAGE SQL IMMUTABLE AS $$
  SELECT NULLIF(TRIM(BOTH '"' FROM j::text), 'null');
$$;

CREATE OR REPLACE FUNCTION public.fs_bool(j JSONB, default_val BOOLEAN DEFAULT FALSE)
RETURNS BOOLEAN LANGUAGE SQL IMMUTABLE AS $$
  SELECT CASE
    WHEN j IS NULL OR j = 'null'::jsonb THEN default_val
    WHEN jsonb_typeof(j) = 'boolean' THEN (j #>> '{}')::boolean
    ELSE default_val
  END;
$$;

CREATE OR REPLACE FUNCTION public.fs_num(j JSONB)
RETURNS DOUBLE PRECISION LANGUAGE SQL IMMUTABLE AS $$
  SELECT CASE
    WHEN j IS NULL OR j = 'null'::jsonb THEN NULL
    WHEN jsonb_typeof(j) = 'number' THEN (j #>> '{}')::double precision
    ELSE NULL
  END;
$$;

CREATE OR REPLACE FUNCTION public.fs_timestamp(j JSONB)
RETURNS TIMESTAMPTZ LANGUAGE SQL IMMUTABLE AS $$
  SELECT CASE
    WHEN j IS NULL OR j = 'null'::jsonb THEN NULL
    WHEN j->>'_firestore_type' = 'timestamp' THEN (j->>'value')::timestamptz
    ELSE NULL
  END;
$$;

CREATE TABLE IF NOT EXISTS public.churches (
  id TEXT PRIMARY KEY,
  name TEXT,
  address TEXT,
  logo_url TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ,
  updated_by TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  church_id TEXT REFERENCES public.churches(id) ON DELETE SET NULL,
  leader_id TEXT,
  roles JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  fcm_token TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.leaders (
  id TEXT PRIMARY KEY,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  email TEXT,
  mobile_phone TEXT,
  cell_code TEXT,
  gender TEXT,
  id_document_type TEXT,
  id_document_number TEXT,
  birth_date DATE,
  street TEXT,
  street_number TEXT,
  neighborhood TEXT,
  locality TEXT,
  state_province TEXT,
  postal_code TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  auth_user_id TEXT,
  church_id TEXT REFERENCES public.churches(id) ON DELETE SET NULL,
  registration_source TEXT,
  church_office TEXT,
  app_roles JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
  registered_at TIMESTAMPTZ,
  registered_by TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.cells (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL DEFAULT '',
  name TEXT,
  street TEXT,
  street_number TEXT,
  neighborhood TEXT,
  locality TEXT,
  state_province TEXT,
  postal_code TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  cell_day TEXT,
  leader_id TEXT,
  leader_name TEXT,
  notes TEXT,
  member_count INT,
  church_id TEXT REFERENCES public.churches(id) ON DELETE SET NULL,
  registered_at TIMESTAMPTZ,
  registered_by TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.cell_helpers (
  cell_id TEXT NOT NULL REFERENCES public.cells(id) ON DELETE CASCADE,
  member_id TEXT NOT NULL,
  full_name TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (cell_id, member_id)
);

CREATE TABLE IF NOT EXISTS public.members (
  id TEXT PRIMARY KEY,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  phone TEXT,
  gender TEXT,
  street TEXT,
  street_number TEXT,
  neighborhood TEXT,
  locality TEXT,
  state_province TEXT,
  postal_code TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  id_document_type TEXT,
  id_document_number TEXT,
  birth_date DATE,
  occupation TEXT,
  marital_status TEXT,
  cell_day TEXT,
  cell_time TEXT,
  cell_zone TEXT,
  observations TEXT,
  volunteer TEXT,
  assigned_leader_id TEXT,
  assigned_leader_name TEXT,
  assigned_leader_cell_code TEXT,
  assigned_leader_from_registration BOOLEAN,
  assignment_kind TEXT,
  assigned_cell_id TEXT REFERENCES public.cells(id) ON DELETE SET NULL,
  assigned_cell_code TEXT,
  spiritual_state TEXT,
  assigned_distance_km DOUBLE PRECISION,
  wants_visit BOOLEAN NOT NULL DEFAULT TRUE,
  is_new_believer BOOLEAN NOT NULL DEFAULT FALSE,
  is_baptized BOOLEAN NOT NULL DEFAULT FALSE,
  baptized_at TIMESTAMPTZ,
  entry_source TEXT,
  form_date TIMESTAMPTZ,
  registered_at TIMESTAMPTZ,
  registered_by TEXT,
  church_id TEXT REFERENCES public.churches(id) ON DELETE SET NULL,
  leadership_status TEXT,
  linked_leader_id TEXT,
  promoted_to_leader_at TIMESTAMPTZ,
  registration_source TEXT,
  pastoral_assigned_at TIMESTAMPTZ,
  cell_assigned_at TIMESTAMPTZ,
  search_name TEXT,
  search_last_first TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.member_visits (
  id TEXT PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  leader_id TEXT,
  visit_date TIMESTAMPTZ,
  comment TEXT,
  visit_place TEXT,
  approximate_duration TEXT,
  prayer_performed BOOLEAN NOT NULL DEFAULT FALSE,
  prayer_requests TEXT,
  needs_follow_up BOOLEAN NOT NULL DEFAULT FALSE,
  spiritual_state TEXT,
  registered_at TIMESTAMPTZ,
  registered_by TEXT,
  church_id TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.member_history_events (
  id TEXT PRIMARY KEY,
  member_id TEXT NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  occurred_at TIMESTAMPTZ,
  performed_by TEXT,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.baptism_calendar (
  id TEXT PRIMARY KEY,
  baptism_date DATE,
  time TEXT,
  location TEXT,
  notes TEXT,
  registered_at TIMESTAMPTZ,
  registered_by TEXT,
  church_id TEXT REFERENCES public.churches(id) ON DELETE SET NULL,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.baptism_assigned_members (
  baptism_id TEXT NOT NULL REFERENCES public.baptism_calendar(id) ON DELETE CASCADE,
  member_id TEXT NOT NULL,
  full_name TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (baptism_id, member_id)
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL DEFAULT '',
  recipient_user_id TEXT,
  church_id TEXT,
  leader_id TEXT,
  member_id TEXT,
  member_name TEXT,
  cell_id TEXT,
  cell_code TEXT,
  cell_name TEXT,
  member_count INT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  is_dismissed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.cell_attendance_sessions (
  id TEXT PRIMARY KEY,
  cell_id TEXT NOT NULL REFERENCES public.cells(id) ON DELETE CASCADE,
  cell_code TEXT,
  session_date DATE,
  session_time TEXT,
  place TEXT,
  registered_cell_day TEXT,
  session_weekday TEXT,
  day_differs_from_registered BOOLEAN NOT NULL DEFAULT FALSE,
  note_day_change_for_session BOOLEAN NOT NULL DEFAULT FALSE,
  day_change_reason TEXT,
  registered_place TEXT,
  location_differs_from_registered BOOLEAN NOT NULL DEFAULT FALSE,
  note_location_change_for_session BOOLEAN NOT NULL DEFAULT FALSE,
  location_change_reason TEXT,
  offering_collected TEXT,
  observations TEXT,
  present_count INT,
  total_count INT,
  leader_id TEXT,
  leader_name TEXT,
  registered_at TIMESTAMPTZ,
  registered_by TEXT,
  church_id TEXT,
  records JSONB NOT NULL DEFAULT '[]'::jsonb,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.unassigned_disciples (
  id TEXT PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  gender TEXT,
  church_id TEXT,
  registered_at TIMESTAMPTZ,
  registered_by TEXT,
  raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_members_church ON public.members(church_id);
CREATE INDEX IF NOT EXISTS idx_members_cell ON public.members(assigned_cell_id);
CREATE INDEX IF NOT EXISTS idx_members_leader ON public.members(assigned_leader_id);
CREATE INDEX IF NOT EXISTS idx_cells_church ON public.cells(church_id);
CREATE INDEX IF NOT EXISTS idx_leaders_church ON public.leaders(church_id);
