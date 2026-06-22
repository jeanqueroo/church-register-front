import 'dotenv/config';
import fs from 'node:fs';
import admin from 'firebase-admin';
import pg from 'pg';

const { Pool } = pg;

function requireEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Falta ${name}`);
  return value;
}

function initFirebase() {
  if (admin.apps.length > 0) {
    return admin.firestore();
  }
  const credentialsPath = requireEnv('GOOGLE_APPLICATION_CREDENTIALS');
  const serviceAccount = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId:
      process.env.FIREBASE_PROJECT_ID?.trim() || serviceAccount.project_id,
  });
  return admin.firestore();
}

async function countFirestoreDocuments(db) {
  let total = 0;
  const byRoot = {};

  async function walkCollection(collectionRef, rootName) {
    const snapshot = await collectionRef.get();
    for (const doc of snapshot.docs) {
      total += 1;
      byRoot[rootName] = (byRoot[rootName] ?? 0) + 1;
      const subcollections = await doc.ref.listCollections();
      for (const sub of subcollections) {
        await walkCollection(sub, rootName);
      }
    }
  }

  const roots = await db.listCollections();
  for (const root of roots) {
    await walkCollection(root, root.id);
  }

  return { total, byRoot };
}

async function main() {
  const db = initFirebase();
  const pool = new Pool({ connectionString: requireEnv('DATABASE_URL') });

  console.log('Contando Firestore...');
  const firestore = await countFirestoreDocuments(db);

  const pgTotal = await pool.query(
    'SELECT COUNT(*)::int AS count FROM firestore_mirror.documents',
  );
  const pgByRoot = await pool.query(
    `SELECT root_collection, COUNT(*)::int AS count
     FROM firestore_mirror.documents
     GROUP BY root_collection
     ORDER BY root_collection`,
  );

  console.log('\n=== Totales ===');
  console.log(`Firestore:  ${firestore.total}`);
  console.log(`PostgreSQL: ${pgTotal.rows[0].count}`);
  console.log(
    firestore.total === pgTotal.rows[0].count
      ? 'OK: coinciden'
      : 'ATENCIÓN: no coinciden (revisa si la migración terminó bien)',
  );

  console.log('\n=== Por colección raíz (Firestore) ===');
  for (const [name, count] of Object.entries(firestore.byRoot).sort()) {
    console.log(`${name}: ${count}`);
  }

  console.log('\n=== Por colección raíz (PostgreSQL) ===');
  for (const row of pgByRoot.rows) {
    console.log(`${row.root_collection}: ${row.count}`);
  }

  await pool.end();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
