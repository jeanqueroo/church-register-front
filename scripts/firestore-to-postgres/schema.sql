-- Espejo de Firestore en PostgreSQL (migración one-shot).
-- No reemplaza la app: conserva documentos y subcolecciones como JSONB.

CREATE SCHEMA IF NOT EXISTS firestore_mirror;

CREATE TABLE IF NOT EXISTS firestore_mirror.documents (
  path TEXT PRIMARY KEY,
  root_collection TEXT NOT NULL,
  document_id TEXT NOT NULL,
  parent_path TEXT,
  depth INT NOT NULL DEFAULT 0,
  data JSONB NOT NULL,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fs_documents_root
  ON firestore_mirror.documents (root_collection);

CREATE INDEX IF NOT EXISTS idx_fs_documents_parent
  ON firestore_mirror.documents (parent_path);

CREATE INDEX IF NOT EXISTS idx_fs_documents_data
  ON firestore_mirror.documents USING GIN (data);

CREATE TABLE IF NOT EXISTS firestore_mirror.migration_runs (
  id BIGSERIAL PRIMARY KEY,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  finished_at TIMESTAMPTZ,
  firebase_project_id TEXT,
  documents_migrated INT DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'running',
  error_message TEXT
);

COMMENT ON TABLE firestore_mirror.documents IS
  'Copia de documentos Firestore. path = ruta completa (ej. members/abc/visits/xyz).';
