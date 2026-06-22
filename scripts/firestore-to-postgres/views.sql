-- Vistas legibles sobre el espejo JSONB de Firestore.
-- Ejecutar después de migrate: psql ... -f views.sql

CREATE SCHEMA IF NOT EXISTS app;

-- === Colecciones raíz (depth = 0) ===

CREATE OR REPLACE VIEW app.churches AS
SELECT
  document_id AS id,
  path,
  data->>'name' AS name,
  data->>'code' AS code,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'churches' AND depth = 0;

CREATE OR REPLACE VIEW app.users AS
SELECT
  document_id AS id,
  path,
  data->>'email' AS email,
  data->>'fullName' AS full_name,
  data->>'churchId' AS church_id,
  data->>'leaderId' AS leader_id,
  data->'roles' AS roles,
  COALESCE((data->>'isBlocked')::boolean, false) AS is_blocked,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'users' AND depth = 0;

CREATE OR REPLACE VIEW app.members AS
SELECT
  document_id AS id,
  path,
  data->>'firstName' AS first_name,
  data->>'lastName' AS last_name,
  TRIM(CONCAT(data->>'firstName', ' ', data->>'lastName')) AS full_name,
  data->>'phone' AS phone,
  data->>'churchId' AS church_id,
  data->>'assignedCellId' AS assigned_cell_id,
  data->>'assignedCellCode' AS assigned_cell_code,
  data->>'assignedLeaderId' AS assigned_leader_id,
  COALESCE((data->>'isBaptized')::boolean, false) AS is_baptized,
  COALESCE((data->>'isNewBeliever')::boolean, false) AS is_new_believer,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'members' AND depth = 0;

CREATE OR REPLACE VIEW app.leaders AS
SELECT
  document_id AS id,
  path,
  data->>'firstName' AS first_name,
  data->>'lastName' AS last_name,
  TRIM(CONCAT(data->>'firstName', ' ', data->>'lastName')) AS full_name,
  data->>'email' AS email,
  data->>'phone' AS phone,
  data->>'mobile' AS mobile,
  data->>'churchId' AS church_id,
  data->>'cellCode' AS cell_code,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'leaders' AND depth = 0;

CREATE OR REPLACE VIEW app.cells AS
SELECT
  document_id AS id,
  path,
  data->>'code' AS code,
  data->>'name' AS name,
  data->>'leaderId' AS leader_id,
  data->>'leaderName' AS leader_name,
  data->>'churchId' AS church_id,
  data->>'cellDay' AS cell_day,
  COALESCE((data->>'memberCount')::int, 0) AS member_count,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'cells' AND depth = 0;

CREATE OR REPLACE VIEW app.baptism_calendar AS
SELECT
  document_id AS id,
  path,
  data->>'churchId' AS church_id,
  data->>'time' AS time,
  data->>'location' AS location,
  data->>'notes' AS notes,
  data->'assignedMembers' AS assigned_members,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'baptismCalendar' AND depth = 0;

CREATE OR REPLACE VIEW app.notifications AS
SELECT
  document_id AS id,
  path,
  data->>'type' AS type,
  data->>'churchId' AS church_id,
  data->>'recipientUserId' AS recipient_user_id,
  COALESCE((data->>'read')::boolean, false) AS read,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'notifications' AND depth = 0;

CREATE OR REPLACE VIEW app.disciples AS
SELECT
  document_id AS id,
  path,
  data->>'firstName' AS first_name,
  data->>'lastName' AS last_name,
  data->>'churchId' AS church_id,
  data
FROM firestore_mirror.documents
WHERE root_collection = 'disciples' AND depth = 0;

-- === Subcolecciones ===

CREATE OR REPLACE VIEW app.member_visits AS
SELECT
  document_id AS id,
  parent_path AS member_path,
  SPLIT_PART(parent_path, '/', 2) AS member_id,
  path,
  data
FROM firestore_mirror.documents
WHERE path ~ '^members/[^/]+/visits/';

CREATE OR REPLACE VIEW app.member_history AS
SELECT
  document_id AS id,
  parent_path AS member_path,
  SPLIT_PART(parent_path, '/', 2) AS member_id,
  path,
  data->>'type' AS event_type,
  data
FROM firestore_mirror.documents
WHERE path ~ '^members/[^/]+/history/';

CREATE OR REPLACE VIEW app.cell_sessions AS
SELECT
  document_id AS id,
  parent_path AS cell_path,
  SPLIT_PART(parent_path, '/', 2) AS cell_id,
  path,
  data
FROM firestore_mirror.documents
WHERE path ~ '^cells/[^/]+/sessions/';

CREATE OR REPLACE VIEW app.cell_disciples AS
SELECT
  document_id AS id,
  parent_path AS cell_path,
  SPLIT_PART(parent_path, '/', 2) AS cell_id,
  path,
  data
FROM firestore_mirror.documents
WHERE path ~ '^cells/[^/]+/disciples/';

COMMENT ON SCHEMA app IS
  'Vistas sobre firestore_mirror.documents con nombres de colección Firestore.';
