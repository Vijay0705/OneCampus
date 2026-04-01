const { getFirestore, getMessaging, getAdmin } = require('../config/firebase');

const chunk = (items, size) => {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
};

const loadStudentUids = async (db) => {
  const studentsSnap = await db
    .collection('users')
    .where('role', '==', 'student')
    .get();

  return studentsSnap.docs.map((doc) => doc.id);
};

const loadStudentTokens = async (db, studentUids) => {
  if (!studentUids.length) return [];

  const tokens = [];
  const uidChunks = chunk(studentUids, 10);

  for (const uidBatch of uidChunks) {
    const tokenSnap = await db
      .collection('device_tokens')
      .where('uid', 'in', uidBatch)
      .get();

    tokenSnap.forEach((doc) => {
      const data = doc.data();
      if (data.token) {
        tokens.push({ id: doc.id, token: data.token });
      }
    });
  }

  return tokens;
};

const removeInvalidTokens = async (db, invalidDocIds) => {
  if (!invalidDocIds.length) return;

  const batches = chunk(invalidDocIds, 400);
  for (const batchIds of batches) {
    const writeBatch = db.batch();
    for (const id of batchIds) {
      writeBatch.delete(db.collection('device_tokens').doc(id));
    }
    await writeBatch.commit();
  }
};

const sendAnnouncementNotificationToStudents = async ({
  announcementId,
  title,
  description,
}) => {
  const db = getFirestore();
  const messaging = getMessaging();
  const admin = getAdmin();

  const studentUids = await loadStudentUids(db);
  if (!studentUids.length) {
    return { successCount: 0, failureCount: 0, totalTokens: 0 };
  }

  const tokenRecords = await loadStudentTokens(db, studentUids);
  const uniqueMap = new Map();
  tokenRecords.forEach((rec) => {
    if (!uniqueMap.has(rec.token)) {
      uniqueMap.set(rec.token, rec.id);
    }
  });

  const uniqueTokens = [...uniqueMap.keys()];

  if (!uniqueTokens.length) {
    return { successCount: 0, failureCount: 0, totalTokens: 0 };
  }

  const body = description.length > 120
    ? `${description.slice(0, 117)}...`
    : description;

  const messageBatches = chunk(uniqueTokens, 500);

  let successCount = 0;
  let failureCount = 0;
  const invalidDocIds = [];

  for (const tokenBatch of messageBatches) {
    const response = await messaging.sendEachForMulticast({
      tokens: tokenBatch,
      notification: {
        title,
        body,
      },
      data: {
        type: 'announcement',
        announcementId,
        screen: 'announcements',
        click_action: 'OPEN_ANNOUNCEMENT',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'announcements',
          clickAction: 'OPEN_ANNOUNCEMENT',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
      webpush: {
        fcmOptions: {
          link: '/announcements',
        },
      },
    });

    successCount += response.successCount;
    failureCount += response.failureCount;

    response.responses.forEach((item, idx) => {
      if (!item.success && item.error) {
        const code = item.error.code || '';
        const shouldDelete =
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token';

        if (shouldDelete) {
          const failedToken = tokenBatch[idx];
          const docId = uniqueMap.get(failedToken);
          if (docId) invalidDocIds.push(docId);
        }
      }
    });
  }

  await removeInvalidTokens(db, invalidDocIds);

  await db.collection('notification_logs').add({
    type: 'announcement',
    announcementId,
    totalTokens: uniqueTokens.length,
    successCount,
    failureCount,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    totalTokens: uniqueTokens.length,
    successCount,
    failureCount,
  };
};

const sendCanteenStatusNotification = async ({ userId, orderId, status }) => {
  const db = getFirestore();
  const messaging = getMessaging();

  const tokenRecords = await loadStudentTokens(db, [userId]);
  if (!tokenRecords.length) return;

  const tokens = tokenRecords.map((r) => r.token);

  let title = 'Order Update 🍛';
  let body = `Your order status is now: ${status.toUpperCase()}`;

  if (status === 'preparing') {
    body = 'The kitchen has started preparing your delicious meal!';
  } else if (status === 'ready') {
    title = 'Ready for Pickup! 🍽️';
    body = 'Your order is hot and ready. Please head to the canteen!';
  }

  await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: {
      type: 'canteen_order',
      orderId,
      status,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'canteen_updates',
      },
    },
  });

  await db.collection('notification_logs').add({
    type: 'canteen_order',
    userId,
    orderId,
    status,
    totalTokens: tokens.length,
    createdAt: new Date().toISOString(),
  });
};

module.exports = {
  sendAnnouncementNotificationToStudents,
  sendCanteenStatusNotification,
};