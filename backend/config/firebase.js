const admin = require('firebase-admin');
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();


async function sendPushNotification(uid, title, body) {
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const token = userDoc.exists ? userDoc.data().fcmToken : null;

    if (!token) {
      console.log(`No FCM token saved for user ${uid}, skipping notification`);
      return;
    }

    await admin.messaging().send({
      token,
      notification: { title, body }
    });

  } catch (error) {
    console.log('Push notification failed:', error.message);
  }
}

module.exports = { admin, db, sendPushNotification };
