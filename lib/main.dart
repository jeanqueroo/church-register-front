import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/widgets/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChurchRegisterApp());
}

class ChurchRegisterApp extends StatelessWidget {
  const ChurchRegisterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appDisplayName,
      debugShowCheckedModeBanner: false,
      theme: buildChurchTheme(),
      home: const AuthGate(),
    );
  }
}
