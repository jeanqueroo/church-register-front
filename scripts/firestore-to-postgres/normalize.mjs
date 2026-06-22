import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const { Pool } = pg;

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Falta la variable de entorno ${name}`);
  return value;
}

function text(data, key) {
  const value = data?.[key];
  if (value == null) return null;
  const s = String(value).trim();
  return s.length ? s : null;
}

function bool(data, key, defaultValue = false) {
  const value = data?.[key];
  if (value == null) return defaultValue;
  return Boolean(value);
}

function num(data, key) {
  const value = data?.[key];
  if (value == null) return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function int(data, key) {
  const n = num(data, key);
  return n == null ? null : Math.trunc(n);
}

function ts(data, key) {
  const value = data?.[key];
  if (!value) return null;
  if (value._firestore_type === 'timestamp') return value.value;
  return null;
}

function dateOnly(data, key) {
  const iso = ts(data, key);
  return iso ? iso.slice(0, 10) : null;
}

function jsonArray(data, key) {
  const value = data?.[key];
  return Array.isArray(value) ? value : [];
}

function pathSegment(path, index) {
  return path.split('/').filter(Boolean)[index] ?? null;
}

async function applySqlFile(pool, filename) {
  const sql = fs.readFileSync(new URL(filename, import.meta.url), 'utf8');
  await pool.query(sql);
}

async function truncateRelational(pool) {
  await pool.query(`
    TRUNCATE TABLE
      public.baptism_assigned_members,
      public.member_visits,
      public.member_history_events,
      public.cell_attendance_sessions,
      public.cell_helpers,
      public.baptism_calendar,
      public.notifications,
      public.members,
      public.unassigned_disciples,
      public.cells,
      public.leaders,
      public.users,
      public.churches
    CASCADE
  `);
}

async function loadMirrorDocuments(pool) {
  const result = await pool.query(`
    SELECT path, root_collection, document_id, parent_path, depth, data
    FROM firestore_mirror.documents
    ORDER BY path
  `);
  return result.rows;
}

function groupDocuments(rows) {
  const groups = {
    churches: [],
    users: [],
    leaders: [],
    cells: [],
    members: [],
    memberVisits: [],
    memberHistory: [],
    baptismCalendar: [],
    notifications: [],
    cellSessions: [],
    unassignedDisciples: [],
    cellDisciples: [],
  };

  for (const row of rows) {
    const { path, root_collection, depth, data } = row;
    const doc = { ...row, data };

    if (depth === 0) {
      switch (root_collection) {
        case 'churches':
          groups.churches.push(doc);
          break;
        case 'users':
          groups.users.push(doc);
          break;
        case 'leaders':
          groups.leaders.push(doc);
          break;
        case 'cells':
          groups.cells.push(doc);
          break;
        case 'members':
          groups.members.push(doc);
          break;
        case 'baptismCalendar':
          groups.baptismCalendar.push(doc);
          break;
        case 'notifications':
          groups.notifications.push(doc);
          break;
        case 'disciples':
          groups.unassignedDisciples.push(doc);
          break;
        default:
          break;
      }
      continue;
    }

    if (path.includes('/visits/')) {
      groups.memberVisits.push(doc);
    } else if (path.includes('/history/')) {
      groups.memberHistory.push(doc);
    } else if (path.includes('/sessions/')) {
      groups.cellSessions.push(doc);
    } else if (path.includes('/disciples/')) {
      groups.cellDisciples.push(doc);
    }
  }

  return groups;
}

async function insertChurches(pool, docs) {
  for (const doc of docs) {
    const d = doc.data;
    await pool.query(
      `INSERT INTO public.churches (
        id, name, address, logo_url, latitude, longitude,
        is_blocked, updated_at, updated_by, raw_data
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10::jsonb)`,
      [
        doc.document_id,
        text(d, 'name'),
        text(d, 'address'),
        text(d, 'logoUrl'),
        num(d, 'latitude'),
        num(d, 'longitude'),
        bool(d, 'isBlocked'),
        ts(d, 'updatedAt'),
        text(d, 'updatedBy'),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertUsers(pool, docs) {
  for (const doc of docs) {
    const d = doc.data;
    const roles = jsonArray(d, 'roles');
    if (!roles.length && d.role) {
      roles.push(...(Array.isArray(d.role) ? d.role : [d.role]));
    }
    await pool.query(
      `INSERT INTO public.users (
        id, email, full_name, church_id, leader_id, roles, is_blocked, fcm_token, raw_data
      ) VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7,$8,$9::jsonb)`,
      [
        doc.document_id,
        text(d, 'email'),
        text(d, 'fullName'),
        text(d, 'churchId'),
        text(d, 'leaderId'),
        JSON.stringify(roles),
        bool(d, 'isBlocked'),
        text(d, 'fcmToken'),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertLeaders(pool, docs) {
  for (const doc of docs) {
    const d = doc.data;
    await pool.query(
      `INSERT INTO public.leaders (
        id, first_name, last_name, email, mobile_phone, cell_code, gender,
        id_document_type, id_document_number, birth_date, street, street_number,
        neighborhood, locality, state_province, postal_code, latitude, longitude,
        auth_user_id, church_id, registration_source, church_office, app_roles,
        is_blocked, registered_at, registered_by, raw_data
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,
        $19,$20,$21,$22,$23::jsonb,$24,$25,$26,$27::jsonb
      )`,
      [
        doc.document_id,
        text(d, 'firstName') ?? '',
        text(d, 'lastName') ?? '',
        text(d, 'email'),
        text(d, 'mobilePhone') ?? '',
        text(d, 'cellCode'),
        text(d, 'gender'),
        text(d, 'idDocumentType'),
        text(d, 'idDocumentNumber'),
        dateOnly(d, 'birthDate'),
        text(d, 'street'),
        text(d, 'streetNumber'),
        text(d, 'neighborhood'),
        text(d, 'locality'),
        text(d, 'stateProvince'),
        text(d, 'postalCode'),
        num(d, 'latitude'),
        num(d, 'longitude'),
        text(d, 'authUserId'),
        text(d, 'churchId'),
        text(d, 'registrationSource'),
        text(d, 'churchOffice'),
        JSON.stringify(jsonArray(d, 'appRoles')),
        bool(d, 'isBlocked'),
        ts(d, 'registeredAt'),
        text(d, 'registeredBy'),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertCells(pool, docs, cellIds) {
  for (const doc of docs) {
    const d = doc.data;
    cellIds.add(doc.document_id);
    await pool.query(
      `INSERT INTO public.cells (
        id, code, name, street, street_number, neighborhood, locality,
        state_province, postal_code, latitude, longitude, cell_day,
        leader_id, leader_name, notes, member_count, church_id,
        registered_at, registered_by, raw_data
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20::jsonb
      )`,
      [
        doc.document_id,
        text(d, 'code') ?? '',
        text(d, 'name'),
        text(d, 'street'),
        text(d, 'streetNumber'),
        text(d, 'neighborhood'),
        text(d, 'locality'),
        text(d, 'stateProvince'),
        text(d, 'postalCode'),
        num(d, 'latitude'),
        num(d, 'longitude'),
        text(d, 'cellDay'),
        text(d, 'leaderId'),
        text(d, 'leaderName'),
        text(d, 'notes'),
        int(d, 'memberCount'),
        text(d, 'churchId'),
        ts(d, 'registeredAt'),
        text(d, 'registeredBy'),
        JSON.stringify(d),
      ],
    );

    for (const helper of jsonArray(d, 'helpers')) {
      const memberId = text(helper, 'memberId');
      if (!memberId) continue;
      await pool.query(
        `INSERT INTO public.cell_helpers (cell_id, member_id, full_name)
         VALUES ($1, $2, $3)
         ON CONFLICT DO NOTHING`,
        [doc.document_id, memberId, text(helper, 'fullName') ?? ''],
      );
    }
  }
}

async function insertMembers(pool, docs, cellIds) {
  for (const doc of docs) {
    const d = doc.data;
    let firstName = text(d, 'firstName');
    let lastName = text(d, 'lastName') ?? '';
    if (!firstName) {
      const legacy = text(d, 'fullName') ?? '';
      const parts = legacy.split(/\s+/).filter(Boolean);
      firstName = parts[0] ?? 'Sin nombre';
      lastName = parts.length > 1 ? parts.slice(1).join(' ') : '';
    }

    const assignedCellId = text(d, 'assignedCellId');
    const safeCellId =
      assignedCellId && cellIds.has(assignedCellId) ? assignedCellId : null;

    await pool.query(
      `INSERT INTO public.members (
        id, first_name, last_name, phone, gender, street, street_number,
        neighborhood, locality, state_province, postal_code, latitude, longitude,
        id_document_type, id_document_number, birth_date, occupation, marital_status,
        cell_day, cell_time, cell_zone, observations, volunteer,
        assigned_leader_id, assigned_leader_name, assigned_leader_cell_code,
        assigned_leader_from_registration, assignment_kind, assigned_cell_id,
        assigned_cell_code, spiritual_state, assigned_distance_km, wants_visit,
        is_new_believer, is_baptized, baptized_at, entry_source, form_date,
        registered_at, registered_by, church_id, leadership_status, linked_leader_id,
        promoted_to_leader_at, registration_source, pastoral_assigned_at,
        cell_assigned_at, search_name, search_last_first, raw_data
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,
        $21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,
        $39,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$50::jsonb
      )`,
      [
        doc.document_id,
        firstName,
        lastName,
        text(d, 'phone'),
        text(d, 'gender'),
        text(d, 'street') ?? text(d, 'address'),
        text(d, 'streetNumber'),
        text(d, 'neighborhood'),
        text(d, 'locality'),
        text(d, 'stateProvince'),
        text(d, 'postalCode'),
        num(d, 'latitude'),
        num(d, 'longitude'),
        text(d, 'idDocumentType'),
        text(d, 'idDocumentNumber'),
        dateOnly(d, 'birthDate'),
        text(d, 'occupation'),
        text(d, 'maritalStatus'),
        text(d, 'cellDay'),
        text(d, 'cellTime'),
        text(d, 'cellZone'),
        text(d, 'observations'),
        text(d, 'volunteer'),
        text(d, 'assignedLeaderId'),
        text(d, 'assignedLeaderName'),
        text(d, 'assignedLeaderCellCode'),
        d.assignedLeaderFromRegistration ?? null,
        text(d, 'assignmentKind'),
        safeCellId,
        text(d, 'assignedCellCode'),
        text(d, 'spiritualState'),
        num(d, 'assignedDistanceKm'),
        bool(d, 'wantsVisit', true),
        bool(d, 'isNewBeliever'),
        bool(d, 'isBaptized'),
        ts(d, 'baptizedAt'),
        text(d, 'entrySource'),
        ts(d, 'formDate') ?? ts(d, 'registeredAt'),
        ts(d, 'registeredAt'),
        text(d, 'registeredBy'),
        text(d, 'churchId'),
        text(d, 'leadershipStatus'),
        text(d, 'linkedLeaderId'),
        ts(d, 'promotedToLeaderAt'),
        text(d, 'registrationSource'),
        ts(d, 'pastoralAssignedAt'),
        ts(d, 'cellAssignedAt'),
        text(d, 'searchName'),
        text(d, 'searchLastFirst'),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertMemberVisits(pool, docs, memberIds) {
  for (const doc of docs) {
    const d = doc.data;
    const memberId = text(d, 'memberId') ?? pathSegment(doc.path, 1);
    if (!memberIds.has(memberId)) continue;

    await pool.query(
      `INSERT INTO public.member_visits (
        id, member_id, leader_id, visit_date, comment, visit_place,
        approximate_duration, prayer_performed, prayer_requests, needs_follow_up,
        spiritual_state, registered_at, registered_by, church_id, raw_data
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15::jsonb)`,
      [
        doc.document_id,
        memberId,
        text(d, 'leaderId'),
        ts(d, 'visitDate'),
        text(d, 'comment'),
        text(d, 'visitPlace'),
        text(d, 'approximateDuration'),
        bool(d, 'prayerPerformed'),
        text(d, 'prayerRequests'),
        bool(d, 'needsFollowUp'),
        text(d, 'spiritualState'),
        ts(d, 'registeredAt'),
        text(d, 'registeredBy'),
        text(d, 'churchId'),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertMemberHistory(pool, docs, memberIds) {
  for (const doc of docs) {
    const d = doc.data;
    const memberId = pathSegment(doc.path, 1);
    if (!memberIds.has(memberId)) continue;

    const details =
      d.details && typeof d.details === 'object' && !Array.isArray(d.details)
        ? d.details
        : {};

    await pool.query(
      `INSERT INTO public.member_history_events (
        id, member_id, event_type, occurred_at, performed_by, details, raw_data
      ) VALUES ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb)`,
      [
        doc.document_id,
        memberId,
        text(d, 'type') ?? 'registered',
        ts(d, 'occurredAt'),
        text(d, 'performedBy'),
        JSON.stringify(details),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertBaptismCalendar(pool, docs) {
  for (const doc of docs) {
    const d = doc.data;
    await pool.query(
      `INSERT INTO public.baptism_calendar (
        id, baptism_date, time, location, notes, registered_at, registered_by, church_id, raw_data
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb)`,
      [
        doc.document_id,
        dateOnly(d, 'baptismDate'),
        text(d, 'time'),
        text(d, 'location'),
        text(d, 'notes'),
        ts(d, 'registeredAt'),
        text(d, 'registeredBy'),
        text(d, 'churchId'),
        JSON.stringify(d),
      ],
    );

    for (const assigned of jsonArray(d, 'assignedMembers')) {
      const memberId = text(assigned, 'memberId');
      if (!memberId) continue;
      await pool.query(
        `INSERT INTO public.baptism_assigned_members (baptism_id, member_id, full_name)
         VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`,
        [doc.document_id, memberId, text(assigned, 'fullName') ?? ''],
      );
    }
  }
}

async function insertNotifications(pool, docs) {
  for (const doc of docs) {
    const d = doc.data;
    await pool.query(
      `INSERT INTO public.notifications (
        id, type, recipient_user_id, church_id, leader_id, member_id, member_name,
        cell_id, cell_code, cell_name, member_count, is_read, is_dismissed,
        created_at, raw_data
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15::jsonb
      )`,
      [
        doc.document_id,
        text(d, 'type') ?? '',
        text(d, 'recipientUserId'),
        text(d, 'churchId'),
        text(d, 'leaderId'),
        text(d, 'memberId'),
        text(d, 'memberName'),
        text(d, 'cellId'),
        text(d, 'cellCode'),
        text(d, 'cellName'),
        int(d, 'memberCount'),
        bool(d, 'read'),
        bool(d, 'dismissed'),
        ts(d, 'createdAt'),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertCellSessions(pool, docs, cellIds) {
  for (const doc of docs) {
    const d = doc.data;
    const cellId = text(d, 'cellId') ?? pathSegment(doc.path, 1);
    if (!cellIds.has(cellId)) continue;

    await pool.query(
      `INSERT INTO public.cell_attendance_sessions (
        id, cell_id, cell_code, session_date, session_time, place,
        registered_cell_day, session_weekday, day_differs_from_registered,
        note_day_change_for_session, day_change_reason, registered_place,
        location_differs_from_registered, note_location_change_for_session,
        location_change_reason, offering_collected, observations, present_count,
        total_count, leader_id, leader_name, registered_at, registered_by,
        church_id, records, raw_data
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,
        $20,$21,$22,$23,$24,$25::jsonb,$26::jsonb
      )`,
      [
        doc.document_id,
        cellId,
        text(d, 'cellCode'),
        dateOnly(d, 'sessionDate'),
        text(d, 'sessionTime'),
        text(d, 'place'),
        text(d, 'registeredCellDay'),
        text(d, 'sessionWeekday'),
        bool(d, 'dayDiffersFromRegistered'),
        bool(d, 'noteDayChangeForSession'),
        text(d, 'dayChangeReason'),
        text(d, 'registeredPlace'),
        bool(d, 'locationDiffersFromRegistered'),
        bool(d, 'noteLocationChangeForSession'),
        text(d, 'locationChangeReason'),
        text(d, 'offeringCollected'),
        text(d, 'observations'),
        int(d, 'presentCount'),
        int(d, 'totalCount'),
        text(d, 'leaderId'),
        text(d, 'leaderName'),
        ts(d, 'registeredAt'),
        text(d, 'registeredBy'),
        text(d, 'churchId'),
        JSON.stringify(jsonArray(d, 'records')),
        JSON.stringify(d),
      ],
    );
  }
}

async function insertUnassignedDisciples(pool, docs) {
  for (const doc of docs) {
    const d = doc.data;
    await pool.query(
      `INSERT INTO public.unassigned_disciples (
        id, first_name, last_name, phone, gender, church_id, registered_at, registered_by, raw_data
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb)`,
      [
        doc.document_id,
        text(d, 'firstName'),
        text(d, 'lastName'),
        text(d, 'phone'),
        text(d, 'gender'),
        text(d, 'churchId'),
        ts(d, 'registeredAt'),
        text(d, 'registeredBy'),
        JSON.stringify(d),
      ],
    );
  }
}

async function printSummary(pool) {
  const tables = [
    'churches',
    'users',
    'leaders',
    'cells',
    'cell_helpers',
    'members',
    'member_visits',
    'member_history_events',
    'baptism_calendar',
    'baptism_assigned_members',
    'notifications',
    'cell_attendance_sessions',
    'unassigned_disciples',
  ];

  console.log('\n=== Tablas relacionales ===');
  for (const table of tables) {
    const result = await pool.query(`SELECT COUNT(*)::int AS c FROM public.${table}`);
    console.log(`${table}: ${result.rows[0].c}`);
  }
}

async function main() {
  const databaseUrl = requireEnv('DATABASE_URL');
  const pool = new Pool({ connectionString: databaseUrl });

  try {
    const mirrorCount = await pool.query(
      'SELECT COUNT(*)::int AS c FROM firestore_mirror.documents',
    );
    if (mirrorCount.rows[0].c === 0) {
      throw new Error(
        'No hay datos en firestore_mirror.documents. Ejecuta primero: npm run migrate',
      );
    }

    console.log('Creando esquema relacional...');
    await applySqlFile(pool, './relational_schema.sql');

    console.log('Limpiando tablas public.* ...');
    await truncateRelational(pool);

    console.log('Leyendo espejo Firestore...');
    const rows = await loadMirrorDocuments(pool);
    const groups = groupDocuments(rows);

    const cellIds = new Set();
    const memberIds = new Set();

    console.log('Insertando churches...');
    await insertChurches(pool, groups.churches);

    console.log('Insertando users...');
    await insertUsers(pool, groups.users);

    console.log('Insertando leaders...');
    await insertLeaders(pool, groups.leaders);

    console.log('Insertando cells...');
    await insertCells(pool, groups.cells, cellIds);

    console.log('Insertando members...');
    await insertMembers(pool, groups.members, cellIds);
    for (const doc of groups.members) memberIds.add(doc.document_id);

    console.log('Insertando member_visits...');
    await insertMemberVisits(pool, groups.memberVisits, memberIds);

    console.log('Insertando member_history_events...');
    await insertMemberHistory(pool, groups.memberHistory, memberIds);

    console.log('Insertando baptism_calendar...');
    await insertBaptismCalendar(pool, groups.baptismCalendar);

    console.log('Insertando notifications...');
    await insertNotifications(pool, groups.notifications);

    console.log('Insertando cell_attendance_sessions...');
    await insertCellSessions(pool, groups.cellSessions, cellIds);

    console.log('Insertando unassigned_disciples...');
    await insertUnassignedDisciples(pool, groups.unassignedDisciples);

    await printSummary(pool);
    console.log('\nNormalización completada.');
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error('\nError en normalización:', error);
  process.exit(1);
});
