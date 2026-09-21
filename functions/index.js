const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// ✅ Fix région : fonctions déplacées en europe-west9 pour coller avec
// la région Firestore (Paris) et éviter les sauts réseau transatlantiques.

exports.onNewAnnouncement = functions
  .firestore.document("announcements/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // Vérifier si le mode test est activé
    const statusDoc = await admin.firestore().collection("app_state").doc("status").get();
    if (statusDoc.exists && statusDoc.data().isTestMode === true) {
      console.log("⚠️ Mode Test activé : notification 'annonces' non envoyée.");
      return;
    }

    await sendPushNotification(
      "annonces",
      "📢 " + (data.title || "Nouvelle annonce"),
      data.description || ""
    );
  });

exports.onAppStateUpdate = functions
  .firestore.document("app_state/status")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Mode test: on ne notifie personne
    if (after.isTestMode === true) {
      console.log("⚠️ Mode Test activé : aucune notification d'état envoyée.");
      return;
    }

    // 1. Live Annoncé (state 1)
    if (after.liveState === 1 && before.liveState !== 1) {
      await sendPushNotification(
        "live_annonce",
        "📅 " + (after.liveTitle || "Live Programmé !"),
        after.liveDesc || "Un nouveau live a été programmé, soyez prêts !"
      );
    }

    // 2. Live Démarré (state 2)
    if (after.liveState === 2 && before.liveState !== 2) {
      await sendPushNotification(
        "live_start",
        "🔴 " + (after.liveTitle || "Le Live est lancé !"),
        after.liveDesc || "Rejoignez-nous sur Twitch."
      );
    }

    // 3. Tournoi Annoncé avec Inscription (state 1)
    if (after.tournamentState === 1 && before.tournamentState !== 1) {
      await sendPushNotification(
        "tournois_annonce",
        "🏆 " + (after.tournamentTitle || "Nouveau Tournoi !"),
        "Les inscriptions sont ouvertes ! " + (after.tournamentDesc || "")
      );
    }

    // 4. Tournoi Démarré (state 2)
    if (after.tournamentState === 2 && before.tournamentState !== 2) {
      await sendPushNotification(
        "tournois_start",
        "⚔️ " + (after.tournamentTitle || "Le Tournoi commence !"),
        "L'événement vient de démarrer ! " + (after.tournamentDesc || "")
      );
    }
  });

async function sendPushNotification(topic, title, body) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        icon: "ic_notification",
        color: "#00D4FF",
        sound: "default",
        defaultSound: true,
        defaultVibrateTimings: true
      },
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      title: title,
      body: body,
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
          sound: "default",
        },
      },
    },
    topic: topic,
  };
  try {
    await admin.messaging().send(message);
    console.log(`✅ Notification '${topic}' envoyée :`, title);
  } catch (error) {
    console.error(`❌ Erreur envoi notification '${topic}':`, error);
  }
}
