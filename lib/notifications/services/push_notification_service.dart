import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../auth/services/user_profile_service.dart';
import '../../core/firebase/firebase_bootstrap.dart';

const androidChannelId = 'leader_assignments';
const androidChannelName = 'Asignación de integrantes';

/// Maneja mensajes FCM cuando la app está en segundo plano o cerrada.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await ensureFirebaseInitialized();
}

typedef PushTapCallback = void Function(RemoteMessage message);

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    UserProfileService? userProfileService,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _userProfileService = userProfileService ?? UserProfileService(),
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final UserProfileService _userProfileService;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _initialized = false;
  String? _registeredUid;
  PushTapCallback? _onNotificationTap;

  Future<void> initialize({PushTapCallback? onNotificationTap}) async {
    if (onNotificationTap != null) {
      _onNotificationTap = onNotificationTap;
    }
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (_) {},
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              androidChannelId,
              androidChannelName,
              description: 'Avisos cuando te asignan un integrante',
              importance: Importance.high,
            ),
          );
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_dispatchTap);
  }

  Future<void> registerForUser(String uid) async {
    await initialize(onNotificationTap: _onNotificationTap);

    if (_registeredUid == uid) {
      await _saveCurrentToken(uid);
      return;
    }
    _registeredUid = uid;

    if (!kIsWeb && Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    await _saveCurrentToken(uid);

    _messaging.onTokenRefresh.listen((token) {
      _userProfileService.saveFcmToken(uid: uid, token: token);
    });
  }

  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _dispatchTap(message);
    }
  }

  Future<void> _saveCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _userProfileService.saveFcmToken(uid: uid, token: token);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  void _dispatchTap(RemoteMessage message) {
    _onNotificationTap?.call(message);
  }
}
