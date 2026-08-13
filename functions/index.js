const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const ANDROID_CHANNEL_ID = 'leader_assignments';
const FUNCTIONS_REGION = 'southamerica-west1';
const ADMIN_ROLES = new Set(['admin', 'superadmin']);

function isAdminCaller(roles) {
  if (!Array.isArray(roles)) return false;
  return roles.some((role) => ADMIN_ROLES.has(String(role)));
}

/**
 * Admin actualiza el correo de login (Auth + users) de un líder/usuario.
 */
exports.updateUserEmailByAdmin = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Debes iniciar sesión.');
    }

    const db = getFirestore();
    const callerSnap = await db.collection('users').doc(request.auth.uid).get();
    if (!callerSnap.exists || !isAdminCaller(callerSnap.data()?.roles)) {
      throw new HttpsError(
        'permission-denied',
        'Solo un administrador puede cambiar el correo.',
      );
    }

    const uid = String(request.data?.uid || '').trim();
    const email = String(request.data?.email || '').trim().toLowerCase();
    if (!uid || !email || !email.includes('@')) {
      throw new HttpsError(
        'invalid-argument',
        'uid y email válidos son requeridos.',
      );
    }

    try {
      await getAuth().updateUser(uid, { email });
    } catch (error) {
      const code = error?.code || '';
      if (code === 'auth/email-already-exists') {
        throw new HttpsError('already-exists', 'Ese correo ya está en uso.');
      }
      if (code === 'auth/invalid-email') {
        throw new HttpsError('invalid-argument', 'Correo inválido.');
      }
      if (code === 'auth/user-not-found') {
        throw new HttpsError('not-found', 'Usuario Auth no encontrado.');
      }
      console.error('updateUserEmailByAdmin Auth error', error);
      throw new HttpsError('internal', 'No se pudo actualizar el correo de Auth.');
    }

    await db.collection('users').doc(uid).set(
      {
        email,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.auth.uid,
      },
      { merge: true },
    );

    return { ok: true, email };
  },
);

exports.notifyLeaderOnMemberAssigned = onDocumentCreated(
  {
    document: 'notifications/{notificationId}',
    region: FUNCTIONS_REGION,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.type !== 'member_assigned') {
      return;
    }

    const db = getFirestore();
    let uid = data.recipientUserId;

    if (!uid && data.leaderId) {
      const users = await db
        .collection('users')
        .where('leaderId', '==', data.leaderId)
        .limit(1)
        .get();
      if (!users.empty) {
        uid = users.docs[0].id;
      }
    }

    if (!uid) {
      console.log('Sin usuario destino para leaderId', data.leaderId);
      return;
    }

    const userSnap = await db.collection('users').doc(uid).get();
    const token = userSnap.data()?.fcmToken;
    if (!token) {
      console.log('Usuario sin fcmToken:', uid);
      return;
    }

    const memberName = data.memberName || 'un integrante';

    await getMessaging().send({
      token,
      notification: {
        title: 'Nuevo integrante asignado',
        body: `Se te asignó a ${memberName}`,
      },
      data: {
        type: 'member_assigned',
        memberId: data.memberId || '',
        leaderId: data.leaderId || '',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: ANDROID_CHANNEL_ID,
        },
      },
    });
  },
);
