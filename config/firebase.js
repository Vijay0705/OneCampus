const admin = require('firebase-admin');

let firestoreDb = null;
let realtimeDb = null;
let storageBucket = null;

function initFirebase() {
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : '';
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const databaseURL = process.env.FIREBASE_DATABASE_URL;
  const storageBucketName =
    process.env.FIREBASE_STORAGE_BUCKET || `${projectId}.appspot.com`;

  if (!projectId || !privateKey || !clientEmail || !databaseURL) {
    throw new Error(
      'Missing Firebase environment variables. Check FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL, FIREBASE_DATABASE_URL.',
    );
  }

  const serviceAccount = {
    project_id: projectId,
    private_key: privateKey,
    client_email: clientEmail,
  };

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL,
      storageBucket: storageBucketName,
    });
  }

  firestoreDb = admin.firestore();
  realtimeDb = admin.database();
  storageBucket = admin.storage().bucket();

  console.log('Firebase initialized');
}

function getFirestore() {
  return firestoreDb;
}

function getRealtimeDb() {
  return realtimeDb;
}

function getStorageBucket() {
  return storageBucket;
}

function getMessaging() {
  return admin.messaging();
}

function getAdmin() {
  return admin;
}

module.exports = {
  initFirebase,
  getFirestore,
  getRealtimeDb,
  getStorageBucket,
  getMessaging,
  getAdmin,
};