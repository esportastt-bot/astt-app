# Suivi du Projet - ASTT E-Sport (V2)

Ce document résume l'état d'avancement de l'application Flutter ASTT E-Sport, conçu pour faciliter la reprise du projet dans une nouvelle session ou avec un autre développeur.

## ✅ Ce qui a été accompli
1. **Initialisation & Architecture** :
   - Projet Flutter configuré.
   - Découpage propre de l'architecture (`screens`, `widgets`, `state`, `utils`).
   - Correction de l'environnement de compilation Android (installation du NDK `28.2.13676358`).
   - Premier déploiement réussi sur appareil physique (ZTE).

2. **Design (Copie exacte de la maquette HTML)** :
   - Ambiance "Dark Mode / Cyberpunk".
   - **Particules animées** en arrière-plan (`CustomPainter` dans `particles_bg.dart`).
   - Effets **Glassmorphism** (transparence et flou via `BackdropFilter`) pour les cartes et le menu de navigation.
   - Animation de pulsation colorée ("Glow") sur la carte Twitch quand le live est actif.
   - Menu Modal "Réseaux" (Discord / Twitch) fonctionnel et stylisé.

3. **Backend & Base de données (Firebase)** :
   - Projet Firebase créé et lié à l'application (`flutterfire configure`).
   - Dépendances intégrées : `firebase_core`, `cloud_firestore`, `provider`.
   - Modèle de données `AppState` fonctionnel (écoute en temps réel).
   - Règles de sécurité Firestore paramétrées temporairement en mode ouvert pour les tests.

4. **Fonctionnalités Interactives** :
   - L'écran "Staff" permet d'activer/désactiver le Live et le Tournoi.
   - Ces actions mettent à jour Firestore instantanément.
   - L'écran "Accueil" écoute Firestore et affiche/masque les cartes Twitch et HelloAsso en temps réel.

---

## 🚀 Ce qu'il reste à faire (Prochaines étapes)

1. **Dynamiser les Annonces (Firestore)** :
   - *Actuellement* : Les cartes d'annonces ("Nouvelle organisation", "Retour sur l'événement") sont codées en dur dans le design.
   - *À faire* : Créer une collection `announcements` dans Firestore, et remplacer les cartes en dur par un `StreamBuilder` ou un Provider pour afficher les annonces depuis la base de données. Ajouter la possibilité de créer des annonces depuis l'onglet Staff.

2. **Sécuriser l'Espace Staff (Authentification)** :
   - *Actuellement* : L'onglet Staff est libre d'accès, et tout le monde peut modifier la base de données.
   - *À faire* :
     - Configurer `firebase_auth`.
     - Cacher la vue Staff derrière un écran de connexion (Email/Mot de passe).
     - Mettre à jour les règles Firestore (`firestore.rules`) pour n'autoriser l'écriture (`allow write`) que si l'utilisateur est authentifié (`if request.auth != null;`).

3. **Notifications Push (FCM)** :
   - *Actuellement* : Les changements apparaissent dans l'app, mais l'utilisateur n'est pas notifié si l'app est fermée.
   - *À faire* :
     - Installer `firebase_messaging`.
     - Demander la permission d'envoi de notifications au démarrage de l'app.
     - (Optionnel) Créer une fonction (Cloud Function) qui envoie une notification à tout le monde lorsqu'un bouton (Live/Tournoi/Annonce) est activé par le staff.

4. **Liens Externes** :
   - Ajouter les vrais liens web vers les boutons "Rejoindre le stream" (Twitch) et "S'inscrire" (HelloAsso) via le package `url_launcher`.
