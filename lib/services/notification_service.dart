import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

// Cette fonction doit obligatoirement être isolée (top-level) pour que
// le téléphone puisse la réveiller même si l'application est totalement fermée.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ✅ FIX #1 : Toujours passer les options Firebase dans l'isolat d'arrière-plan.
  // Sans options, Firebase.initializeApp() échoue silencieusement dans cet isolat
  // séparé, ce qui empêche toutes les notifications en arrière-plan / app fermée.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Notification reçue en arrière-plan : ${message.notification?.title}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal Android (référencé aussi dans AndroidManifest.xml et index.js)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications Importantes',
    description: 'Ce canal est utilisé pour les notifications importantes.',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    // 1. Demander la permission à l'utilisateur (popup native Android 13+ / iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permissions de notifications accordées.');
    } else {
      debugPrint('❌ Permissions refusées : ${settings.authorizationStatus}');
    }

    // 2. Initialisation de flutter_local_notifications pour le premier plan
    // L'icône doit être un drawable monochrome (blanc sur fond transparent).
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    // Création du canal Android (obligatoire pour Android 8+, API 26+)
    // Le canal est créé ici pour qu'il existe AVANT toute réception FCM,
    // même si l'app est lancée pour la première fois.
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Pour que iOS affiche la notification en premier plan
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Handler quand l'app est fermée ou en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handler quand l'app est OUVERTE (en premier plan)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Notification reçue en premier plan: ${message.notification?.title}');

      final notification = message.notification;

      // On affiche la notification locale dès qu'un bloc notification existe,
      // sans conditionner sur la présence d'un payload android spécifique.
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_notification',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // 5. ✅ FIX ZTE / Android 12 : demander l'exemption de la batterie
    // Les constructeurs comme ZTE, Xiaomi, Huawei appliquent une optimisation
    // agressive qui tue les services FCM en arrière-plan. Cette popup système
    // demande à l'utilisateur d'exclure l'app de la gestion batterie,
    // garantissant la réception des notifications même app fermée.
    await _requestBatteryOptimizationExemption();

    // 6. Log du token FCM (utile pour tester depuis la console Firebase)
    final token = await _messaging.getToken();
    debugPrint('📱 FCM Token: $token');
  }

  /// Demande l'exemption de la batterie sur Android (une seule fois).
  /// Sans cette exemption, les constructeurs ZTE, Xiaomi, Huawei, etc.
  /// peuvent tuer le service FCM et bloquer les notifications.
  static Future<void> _requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool('battery_opt_requested') ?? false;

    if (alreadyRequested) {
      debugPrint('🔋 Exemption batterie : déjà demandée précédemment.');
      return;
    }

    debugPrint('🔋 Demande d\'exemption de la batterie pour Android...');

    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        // Package de l'application — doit correspondre à l'applicationId
        data: 'package:com.asttesport.application',
      );
      await intent.launch();

      // Marquer comme demandé pour ne plus afficher la popup au prochain lancement
      await prefs.setBool('battery_opt_requested', true);
      debugPrint('✅ Popup d\'exemption batterie affichée.');
    } catch (e) {
      // Certains appareils ou émulateurs ne supportent pas cet intent.
      // On ignore l'erreur silencieusement.
      debugPrint('⚠️ Exemption batterie impossible sur cet appareil : $e');
      await prefs.setBool('battery_opt_requested', true);
    }
  }
}
