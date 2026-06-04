import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/widgets/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notifications/services/push_notification_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ChurchRegisterApp());
}

class ChurchRegisterApp extends StatelessWidget {
  const ChurchRegisterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: buildChurchTheme(),
      home: const AuthGate(),
    );
  }
}
