import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Inicializa Firebase si hace falta.
///
/// En Android el SDK nativo puede crear `[DEFAULT]` antes que Dart; en ese caso
/// [Firebase.apps] sigue vacío y un `initializeApp` directo lanza duplicate-app.
Future<void> ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }
}
