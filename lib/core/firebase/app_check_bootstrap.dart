import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Activa App Check para Storage, Firestore y demás servicios Firebase.
Future<void> activateFirebaseAppCheck() async {
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider(),
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  if (kDebugMode) {
    await _logDebugTokenHint();
  }
}

/// Obtiene token App Check antes de subir archivos a Storage.
/// Lanza [FirebaseException] con código `app-check` si no hay token válido.
Future<void> ensureAppCheckTokenForUpload() async {
  try {
    final token = await FirebaseAppCheck.instance.getToken(true);
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
    rethrow;
  }
}

bool _isThrottled(FirebaseException e) {
  final message = (e.message ?? '').toLowerCase();
  return message.contains('too many attempts');
}

Future<void> _logDebugTokenHint() async {
  try {
    await FirebaseAppCheck.instance.getToken(true);
  } on FirebaseException catch (e) {
    debugPrint(
      'App Check DEBUG: ${e.message ?? e.code}. '
      'Busca en logcat "App Check debug token" y regístralo en '
      'Firebase Console → App Check → Android → Manage debug tokens. '
      'Luego cierra la app por completo y vuelve a abrirla.',
    );
  } catch (e) {
    debugPrint('App Check DEBUG error: $e');
  }
}
