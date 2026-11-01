import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../config/app_check_debug_token.dart';

/// Activa App Check para Storage, Firestore y demás servicios Firebase.
Future<void> activateFirebaseAppCheck() async {
  final androidDebug = kDebugMode
      ? AndroidDebugProvider(
          debugToken:
              appCheckDebugToken.isNotEmpty ? appCheckDebugToken : null,
        )
      : null;

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? androidDebug!
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider(),
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  if (kDebugMode) {
    _logDebugTokenHint();
  }
}

/// Obtiene token App Check antes de subir archivos a Storage.
///
/// No intenta subir con token placeholder: Storage rechaza con 403.
Future<void> ensureAppCheckTokenForUpload() async {
  try {
    // Usar caché primero; forzar refresh solo si hace falta (evita throttling).
    var token = await FirebaseAppCheck.instance.getToken(false);
    if (token == null || token.isEmpty) {
      token = await FirebaseAppCheck.instance.getToken(true);
    }
    if (token == null || token.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_app_check',
        code: 'app-check-token-missing',
        message: 'App Check token is null',
      );
    }
    if (kDebugMode) {
      debugPrint('App Check: token listo para Storage (${token.length} chars)');
    }
  } on FirebaseException catch (e) {
    if (_isThrottled(e)) {
      throw FirebaseException(
        plugin: 'firebase_app_check',
        code: 'app-check-throttled',
        message: e.message,
      );
    }
    if (e.code == 'app-check-token-missing' || e.code == 'app-check-throttled') {
      rethrow;
    }
    // Errores genéricos (p. ej. code=unknown) al pedir token: tratar como App Check.
    throw FirebaseException(
      plugin: 'firebase_app_check',
      code: 'app-check-token-missing',
      message: e.message ?? e.code,
    );
  }
}

bool _isThrottled(FirebaseException e) {
  final message = (e.message ?? '').toLowerCase();
  return e.code == 'app-check-throttled' ||
      message.contains('too many attempts');
}

void _logDebugTokenHint() {
  if (appCheckDebugToken.isNotEmpty) {
    debugPrint(
      'App Check DEBUG: usando token fijo (APP_CHECK_DEBUG_TOKEN). '
      'Debe estar registrado en Firebase Console → App Check → Android '
      '(proyecto church-register-pro si usas google-services de pro).',
    );
    return;
  }
  debugPrint(
    'App Check DEBUG: el token NO sale en la consola de Flutter. Opciones:\n'
    '  1) Terminal: adb logcat -s DebugAppCheckProvider\n'
    '  2) Firebase Console → App Check → Android → Manage debug tokens → '
    'Generate token, luego:\n'
    '     flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=TU-TOKEN',
  );
}
