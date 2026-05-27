const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const ANDROID_CHANNEL_ID = 'leader_assignments';

exports.notifyLeaderOnMemberAssigned = onDocumentCreated(
  'notifications/{notificationId}',
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
