const admin = require('firebase-admin');
admin.initializeApp({
  projectId: "astt-e-sport"
});

async function run() {
  const db = admin.firestore();
  await db.collection('app_state').doc('status').set({
    latestAppVersionCode: 5,
    updateUrl: "https://astt-e-sport.web.app/ASTT_Esport_v1.04.apk",
    updateMessage: "Correctif : Réception des notifications même lorsque l'application est fermée."
  }, { merge: true });
  console.log("Firestore mis à jour !");
  process.exit(0);
}

run();
