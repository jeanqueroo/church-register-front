import 'dotenv/config';
import fs from 'node:fs';
import admin from 'firebase-admin';
import pg from 'pg';

const { Pool } = pg;

const BATCH_SIZE = Number.parseInt(process.env.BATCH_SIZE ?? '200', 10);

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Falta la variable de entorno ${name}`);
  }
  return value;
}

function initFirebase() {
  const credentialsPath = requireEnv('GOOGLE_APPLICATION_CREDENTIALS');
  if (!fs.existsSync(credentialsPath)) {
    throw new Error(
      `No existe el archivo de credenciales: ${credentialsPath}\n` +
        'Coloca el JSON de Firebase en scripts/firestore-to-postgres/secrets/service-account.json',
    );
  }
  const stat = fs.statSync(credentialsPath);
  if (!stat.isFile()) {
    throw new Error(
      `${credentialsPath} no es un archivo (¿es una carpeta?).\n` +
        'En Windows Docker a veces crea una carpeta vacía si el JSON no existía al montar.\n' +
        'Elimínala y copia el JSON real con ese nombre.',
    );
  }

  const serviceAccount = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
  const projectId =
    process.env.FIREBASE_PROJECT_ID?.trim() || serviceAccount.project_id;

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId,
  });

  return { projectId, db: admin.firestore() };
}

function serializeFirestoreValue(value) {
  if (value === null || value === undefined) return null;

  if (value instanceof admin.firestore.Timestamp) {
    return { _firestore_type: 'timestamp', value: value.toDate().toISOString() };
  }
  if (value instanceof admin.firestore.GeoPoint) {
    return {
      _firestore_type: 'geopoint',
      latitude: value.latitude,
      longitude: value.longitude,
    };
  }
  if (value instanceof admin.firestore.DocumentReference) {
    return { _firestore_type: 'reference', path: value.path };
  }
  if (value instanceof admin.firestore.VectorValue) {
    return { _firestore_type: 'vector', values: [...value.toArray()] };
  }
  if (Array.isArray(value)) {
    return value.map(serializeFirestoreValue);
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [key, nested] of Object.entries(value)) {
      out[key] = serializeFirestoreValue(nested);
    }
    return out;
  }
  return value;
}

function parsePath(path) {
  const segments = path.split('/').filter(Boolean);
  const depth = Math.max(0, Math.floor(segments.length / 2) - 1);
  const rootCollection = segments[0] ?? '';
  const documentId = segments.at(-1) ?? '';
  const parentPath =
    segments.length > 2 ? segments.slice(0, -2).join('/') : null;
  return { rootCollection, documentId, parentPath, depth };
}

async function flushBatch(pool, batch, runId) {
  if (batch.length === 0) return 0;

  const values = [];
  const placeholders = batch.map((row, index) => {
    const base = index * 6;
    values.push(
      row.path,
      row.rootCollection,
      row.documentId,
      row.parentPath,
      row.depth,
      JSON.stringify(row.data),
    );
    return `($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6}::jsonb)`;
  });

  const sql = `
    INSERT INTO firestore_mirror.documents
      (path, root_collection, document_id, parent_path, depth, data)
    VALUES ${placeholders.join(', ')}
    ON CONFLICT (path) DO UPDATE SET
      root_collection = EXCLUDED.root_collection,
      document_id = EXCLUDED.document_id,
      parent_path = EXCLUDED.parent_path,
      depth = EXCLUDED.depth,
      data = EXCLUDED.data,
      migrated_at = NOW()
  `;

  await pool.query(sql, values);
  const count = batch.length;
  batch.length = 0;
  return count;
}

async function exportDocument(docRef, batch, pool, counters) {
  const snap = await docRef.get();
  if (!snap.exists) return;

  const path = docRef.path;
  const meta = parsePath(path);
  batch.push({
    path,
    rootCollection: meta.rootCollection,
    documentId: meta.documentId,
    parentPath: meta.parentPath,
    depth: meta.depth,
    data: serializeFirestoreValue(snap.data()),
  });

  if (batch.length >= BATCH_SIZE) {
    counters.migrated += await flushBatch(pool, batch);
    process.stdout.write(`\rMigrados: ${counters.migrated}`);
  }

  const subcollections = await docRef.listCollections();
  for (const subcollection of subcollections) {
    await exportCollection(subcollection, batch, pool, counters);
  }
}

async function exportCollection(collectionRef, batch, pool, counters) {
  const snapshot = await collectionRef.get();
  for (const doc of snapshot.docs) {
    await exportDocument(doc.ref, batch, pool, counters);
  }
}

async function exportAllRootCollections(db, batch, pool, counters) {
  const rootCollections = await db.listCollections();
  for (const collectionRef of rootCollections) {
    console.log(`\nColección raíz: ${collectionRef.id}`);
    await exportCollection(collectionRef, batch, pool, counters);
  }
}

async function main() {
  const databaseUrl = requireEnv('DATABASE_URL');
  const { projectId, db } = initFirebase();
  const pool = new Pool({ connectionString: databaseUrl });

  console.log(`Proyecto Firebase: ${projectId}`);
  console.log('Creando esquema en PostgreSQL...');
  const schemaSql = fs.readFileSync(new URL('./schema.sql', import.meta.url), 'utf8');
  await pool.query(schemaSql);

  const run = await pool.query(
    `INSERT INTO firestore_mirror.migration_runs (firebase_project_id, status)
     VALUES ($1, 'running') RETURNING id`,
    [projectId],
  );
  const runId = run.rows[0].id;

  const batch = [];
  const counters = { migrated: 0 };

  try {
    console.log('Exportando Firestore (incluye subcolecciones)...');
    await exportAllRootCollections(db, batch, pool, counters);
    counters.migrated += await flushBatch(pool, batch);
    process.stdout.write(`\rMigrados: ${counters.migrated}\n`);

    await pool.query(
      `UPDATE firestore_mirror.migration_runs
       SET finished_at = NOW(), documents_migrated = $1, status = 'completed'
       WHERE id = $2`,
      [counters.migrated, runId],
    );

    console.log('\nMigración completada.');
    console.log(`Documentos en PostgreSQL: ${counters.migrated}`);
    console.log('Ejecuta: npm run verify');
  } catch (error) {
    counters.migrated += await flushBatch(pool, batch).catch(() => 0);
    await pool.query(
      `UPDATE firestore_mirror.migration_runs
       SET finished_at = NOW(), documents_migrated = $1, status = 'failed', error_message = $2
       WHERE id = $3`,
      [counters.migrated, String(error?.message ?? error), runId],
    );
    throw error;
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error('\nError en migración:', error);
  process.exit(1);
});
