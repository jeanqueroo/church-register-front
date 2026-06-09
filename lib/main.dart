import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/widgets/auth_gate.dart';
import 'core/firebase/app_check_bootstrap.dart';
import 'core/locale/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
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
  await activateFirebaseAppCheck();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final localeController = await LocaleController.load();
  final themeController = await ThemeController.load();
  runApp(ChurchRegisterApp(
    localeController: localeController,
    themeController: themeController,
  ));
}

class ChurchRegisterApp extends StatelessWidget {
  const ChurchRegisterApp({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: themeController,
      child: AppLocaleScope(
        controller: localeController,
        child: ListenableBuilder(
          listenable: Listenable.merge([localeController, themeController]),
          builder: (context, _) {
            return MaterialApp(
              navigatorKey: rootNavigatorKey,
              title: appDisplayName,
              debugShowCheckedModeBanner: false,
              theme: buildChurchTheme(palette: themeController.lightPalette),
              darkTheme:
                  buildChurchDarkTheme(palette: themeController.darkPalette),
              themeMode: themeController.themeMode,
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
      ),
    );
  }
}
