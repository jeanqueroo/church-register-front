import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Plataforma no soportada: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANYcA8s0GlHDLxfv1sVfhHLzZ8-eacvSU',
    appId: '1:1096220304922:android:d60cb69bb0d952ba4713a3',
    messagingSenderId: '1096220304922',
    projectId: 'church-register-ce4de',
    storageBucket: 'church-register-ce4de.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: '1096220304922',
    projectId: 'church-register-ce4de',
    storageBucket: 'church-register-ce4de.firebasestorage.app',
    iosBundleId: 'com.church.register.churchRegister',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TU_API_KEY_WEB',
    appId: 'TU_APP_ID_WEB',
    messagingSenderId: '1096220304922',
    projectId: 'church-register-ce4de',
    storageBucket: 'church-register-ce4de.firebasestorage.app',
    authDomain: 'church-register-ce4de.firebaseapp.com',
  );
}
