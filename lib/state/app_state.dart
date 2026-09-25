import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppState extends ChangeNotifier {
  int liveState = 0;
  DateTime? liveScheduledDate;
  
  int tournamentState = 0;
  DateTime? tournamentRegistrationEndDate;
  DateTime? tournamentStartDate;
  
  String? tournamentUrl;
  String twitchUrl = "https://twitch.tv/mon_asso";
  String youtubeUrl = "https://youtube.com";

  String liveTitle = "WEBTV";
  String liveDesc = "On est en live, rejoignez-nous !";
  
  String tournamentTitle = "Tournoi Débutant - Saison 1";
  String tournamentDesc = "Les inscriptions pour le prochain tournoi sont ouvertes. Les places sont limitées !";
  String discordUrl = "https://discord.gg/votre_lien_ici";

  bool isTestMode = false;
  String currentAppVersionName = "Chargement...";
  String latestAppVersionName = "";
  String updateUrl = "";
  String updateMessage = "Une nouvelle version est disponible !";
  
  bool get isUpdateAvailable => 
      latestAppVersionName.isNotEmpty && 
      currentAppVersionName != "Chargement..." && 
      latestAppVersionName != currentAppVersionName;

  User? currentUser;
  bool isStaff = false;
  bool isAdminUnlocked = false; // gardÃ© pour rÃ©trocompatibilitÃ© si besoin

  bool notifyAnnouncements = true;
  bool notifyLiveAnnounced = true;
  bool notifyLiveStart = true;
  bool notifyTournamentAnnounced = true;
  bool notifyTournamentStart = true;
  
  bool isTutorialMode = false;
  bool tutorialShowLive = false;
  bool tutorialShowTournament = false;
  
  bool get displayLive {
    if (isTutorialMode) return tutorialShowLive;
    if (liveState == 2) return true;
    if (liveState == 1 && liveScheduledDate != null) {
      final now = DateTime.now();
      final endOfDay = DateTime(liveScheduledDate!.year, liveScheduledDate!.month, liveScheduledDate!.day, 23, 59, 59);
      if (now.isAfter(liveScheduledDate!) && now.isBefore(endOfDay)) return true;
    }
    return false;
  }

  bool get displayLiveScheduled {
    if (liveState != 1 || liveScheduledDate == null) return false;
    final now = DateTime.now();
    return now.isBefore(liveScheduledDate!);
  }

  bool get displayTournament {
    if (isTutorialMode) return tutorialShowTournament;
    if (tournamentState == 1) {
      if (tournamentRegistrationEndDate != null && DateTime.now().isAfter(tournamentRegistrationEndDate!)) {
        return false;
      }
      return true;
    }
    return false;
  }

  bool get displayTournamentScheduled {
    bool shouldShow = (tournamentState == 2);
    if (tournamentState == 1 && tournamentRegistrationEndDate != null && DateTime.now().isAfter(tournamentRegistrationEndDate!)) {
      shouldShow = true;
    }
    if (!shouldShow || tournamentStartDate == null) return false;
    final now = DateTime.now();
    final endOfDay = DateTime(tournamentStartDate!.year, tournamentStartDate!.month, tournamentStartDate!.day, 23, 59, 59);
    return now.isBefore(endOfDay);
  }

  AppState() {
    _initPackageInfo();
    _listenToState();
    _listenToAuth();
    _initNotificationSettings();
    _startVisibilityTimer();
  }

  void _startVisibilityTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (liveScheduledDate != null || tournamentStartDate != null) {
        notifyListeners();
      }
    });
  }

  void refreshUI() => notifyListeners();

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    String v = info.version;
    if (v.endsWith('.0')) v = v.substring(0, v.length - 2);
    currentAppVersionName = v; 
    notifyListeners();
  }

  Future<void> _initNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    notifyAnnouncements = prefs.getBool('notify_annonces') ?? true;
    notifyLiveAnnounced = prefs.getBool('notify_live_annonce') ?? true;
    notifyLiveStart = prefs.getBool('notify_live_start') ?? true;
    notifyTournamentAnnounced = prefs.getBool('notify_tournois_annonce') ?? true;
    notifyTournamentStart = prefs.getBool('notify_tournois_start') ?? true;
    notifyListeners();
    _applyNotificationSubscriptions();
  }

  void _applyNotificationSubscriptions() {
    final messaging = FirebaseMessaging.instance;
    notifyAnnouncements ? messaging.subscribeToTopic('annonces') : messaging.unsubscribeFromTopic('annonces');
    notifyLiveAnnounced ? messaging.subscribeToTopic('live_annonce') : messaging.unsubscribeFromTopic('live_annonce');
    notifyLiveStart ? messaging.subscribeToTopic('live_start') : messaging.unsubscribeFromTopic('live_start');
    notifyTournamentAnnounced ? messaging.subscribeToTopic('tournois_annonce') : messaging.unsubscribeFromTopic('tournois_annonce');
    notifyTournamentStart ? messaging.subscribeToTopic('tournois_start') : messaging.unsubscribeFromTopic('tournois_start');
  }

  Future<void> toggleNotifyAnnouncements(bool value) async {
    notifyAnnouncements = value; notifyListeners();
    final prefs = await SharedPreferences.getInstance(); await prefs.setBool('notify_annonces', value);
    _applyNotificationSubscriptions();
  }

  Future<void> toggleNotifyLiveAnnounced(bool value) async {
    notifyLiveAnnounced = value; notifyListeners();
    final prefs = await SharedPreferences.getInstance(); await prefs.setBool('notify_live_annonce', value);
    _applyNotificationSubscriptions();
  }

  Future<void> toggleNotifyLiveStart(bool value) async {
    notifyLiveStart = value; notifyListeners();
    final prefs = await SharedPreferences.getInstance(); await prefs.setBool('notify_live_start', value);
    _applyNotificationSubscriptions();
  }

  Future<void> toggleNotifyTournamentAnnounced(bool value) async {
    notifyTournamentAnnounced = value; notifyListeners();
    final prefs = await SharedPreferences.getInstance(); await prefs.setBool('notify_tournois_annonce', value);
    _applyNotificationSubscriptions();
  }

  Future<void> toggleNotifyTournamentStart(bool value) async {
    notifyTournamentStart = value; notifyListeners();
    final prefs = await SharedPreferences.getInstance(); await prefs.setBool('notify_tournois_start', value);
    _applyNotificationSubscriptions();
  }

  void unlockAdmin() {
    isAdminUnlocked = true;
    notifyListeners();
  }

  void setTutorialState(bool live, bool tournament) {
    isTutorialMode = true; tutorialShowLive = live; tutorialShowTournament = tournament; notifyListeners();
  }

  void endTutorial() {
    isTutorialMode = false; tutorialShowLive = false; tutorialShowTournament = false; notifyListeners();
  }

  Future<void> setSocialUrls(String newTwitchUrl, String newDiscordUrl, String newYoutubeUrl) async {
    try {
      await FirebaseFirestore.instance.collection('app_state').doc('status').set({
        'twitchUrl': newTwitchUrl, 'discordUrl': newDiscordUrl, 'youtubeUrl': newYoutubeUrl,
      }, SetOptions(merge: true));
      twitchUrl = newTwitchUrl; discordUrl = newDiscordUrl; youtubeUrl = newYoutubeUrl; notifyListeners();
    } catch (e) {
      debugPrint("Erreur URL: $e");
    }
  }

  Future<void> publishUpdate(String versionName, String url, String message) async {
    try {
      await FirebaseFirestore.instance.collection('app_state').doc('status').set({
        'latestAppVersionName': versionName, 'updateUrl': url, 'updateMessage': message,
      }, SetOptions(merge: true));
    } catch (e) { debugPrint("Erreur MAJ: $e"); }
  }

  Future<void> setTestMode(bool value) async {
    try {
      await FirebaseFirestore.instance.collection('app_state').doc('status').set({'isTestMode': value}, SetOptions(merge: true));
      isTestMode = value; notifyListeners();
    } catch (e) { debugPrint("Erreur TestMode: $e"); }
  }

  void _listenToAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      currentUser = user;
      if (user != null) {
        _fetchUserProfile(user.uid);
      } else {
        isStaff = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        isStaff = doc.data()?['isStaff'] ?? false;
      } else {
        isStaff = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur auth profile: $e");
    }
  }

  Future<void> createUserProfile(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'isStaff': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      isStaff = false;
      notifyListeners();
    }
  }

  void _listenToState() {
    FirebaseFirestore.instance.collection('app_state').doc('status').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        isTestMode = data['isTestMode'] ?? false;
        liveState = data.containsKey('liveState') ? data['liveState'] as int : ((data['isLiveActive'] ?? false) ? 2 : 0);
        liveScheduledDate = data['liveScheduledDate'] != null ? (data['liveScheduledDate'] as Timestamp).toDate() : null;
        tournamentState = data.containsKey('tournamentState') ? data['tournamentState'] as int : ((data['isTournamentActive'] ?? false) ? 1 : 0);
        tournamentRegistrationEndDate = data['tournamentRegistrationEndDate'] != null ? (data['tournamentRegistrationEndDate'] as Timestamp).toDate() : null;
        tournamentStartDate = data['tournamentStartDate'] != null ? (data['tournamentStartDate'] as Timestamp).toDate() : null;
        tournamentUrl = data['tournamentUrl'];
        twitchUrl = data['twitchUrl'] ?? "https://twitch.tv/mon_asso";
        youtubeUrl = data['youtubeUrl'] ?? "https://youtube.com";
        liveTitle = data['liveTitle'] ?? "WEBTV";
        liveDesc = data['liveDesc'] ?? "On est en live, rejoignez-nous !";
        tournamentTitle = data['tournamentTitle'] ?? "Tournoi Débutant - Saison 1";
        tournamentDesc = data['tournamentDesc'] ?? "Les inscriptions pour le prochain tournoi sont ouvertes. Les places sont limitées !";
        discordUrl = data['discordUrl'] ?? "https://discord.gg/votre_lien_ici";
        latestAppVersionName = data['latestAppVersionName']?.toString() ?? data['latestAppVersionCode']?.toString() ?? "";
        updateUrl = data['updateUrl'] ?? "";
        updateMessage = data['updateMessage'] ?? "Une nouvelle version de l'application est disponible, veuillez la télécharger !";
        notifyListeners();
      }
    });
  }

  Future<void> setLiveState(int state, {String? title, String? desc, DateTime? scheduledDate}) async {
    try {
      final Map<String, dynamic> updates = {'liveState': state};
      if (title != null) { updates['liveTitle'] = title; }
      if (desc != null) { updates['liveDesc'] = desc; }
      if (scheduledDate != null) { updates['liveScheduledDate'] = Timestamp.fromDate(scheduledDate); }
      else if (state != 1) { updates['liveScheduledDate'] = FieldValue.delete(); }
      await FirebaseFirestore.instance.collection('app_state').doc('status').update(updates).catchError((_) => FirebaseFirestore.instance.collection('app_state').doc('status').set(updates, SetOptions(merge: true)));
    } catch (e) { debugPrint("Erreur Live: $e"); }
  }

  Future<void> setTournamentState(int state, {String? url, String? title, String? desc, DateTime? regEndDate, DateTime? startDate}) async {
    try {
      final Map<String, dynamic> updates = {'tournamentState': state};
      if (url != null) { updates['tournamentUrl'] = url; }
      if (title != null) { updates['tournamentTitle'] = title; }
      if (desc != null) { updates['tournamentDesc'] = desc; }
      if (regEndDate != null) { updates['tournamentRegistrationEndDate'] = Timestamp.fromDate(regEndDate); }
      else if (state == 0) { updates['tournamentRegistrationEndDate'] = FieldValue.delete(); }
      if (startDate != null) { updates['tournamentStartDate'] = Timestamp.fromDate(startDate); }
      else if (state == 0) { updates['tournamentStartDate'] = FieldValue.delete(); }
      await FirebaseFirestore.instance.collection('app_state').doc('status').update(updates).catchError((_) => FirebaseFirestore.instance.collection('app_state').doc('status').set(updates, SetOptions(merge: true)));
    } catch (e) { debugPrint("Erreur Tournoi: $e"); }
  }

  Future<String?> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

