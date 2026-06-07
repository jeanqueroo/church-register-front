import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/widgets/auth_gate.dart';
import 'core/locale/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notifications/services/push_notification_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final localeController = await LocaleController.load();
  runApp(ChurchRegisterApp(localeController: localeController));
}

class ChurchRegisterApp extends StatelessWidget {
  const ChurchRegisterApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: localeController,
      child: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            title: appDisplayName,
            debugShowCheckedModeBanner: false,
            theme: buildChurchTheme(),
            locale: localeController.locale,
            localeListResolutionCallback: (locales, supportedLocales) {
              return localeController.resolveLocale(locales?.first);
            },
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
