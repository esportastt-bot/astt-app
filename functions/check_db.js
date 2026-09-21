const admin = require('firebase-admin');
admin.initializeApp({
  projectId: "astt-e-sport"
});

async function run() {
  const db = admin.firestore();
  const doc = await db.collection('app_state').doc('status').get();
  console.log("Current Firestore state:", doc.data());
  process.exit(0);
}

run();
