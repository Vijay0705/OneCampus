const admin = require('firebase-admin');

let firestoreDb = null;
let realtimeDb = null;

function initFirebase() {
  const serviceAccount = {
    project_id: process.env.FIREBASE_PROJECT_ID,
    private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'), // ✅ FIXED
    client_email: process.env.FIREBASE_CLIENT_EMAIL,
  };

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: process.env.FIREBASE_DATABASE_URL,
    });
  }

  firestoreDb = admin.firestore();
  realtimeDb = admin.database();

  console.log("✅ Firebase initialized");
}

function getFirestore() {
  return firestoreDb;
}

function getRealtimeDb() {
  return realtimeDb;
}

module.exports = { initFirebase, getFirestore, getRealtimeDb };