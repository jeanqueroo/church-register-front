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
    apiKey: 'AIzaSyC-V8o1o9WKBVZTxx0vaeaUYkrv4UJKfLg',
    appId: '1:401692251430:android:50d2c2b6d227cb6ee31de7',
    messagingSenderId: '401692251430',
    projectId: 'church-register-qa',
    storageBucket: 'church-register-qa.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC5BybJdYxYMP15dnJpJ_-q0ffbaxYOyXo',
    appId: '1:401692251430:ios:3fbfc9dd0144b8fbe31de7',
    messagingSenderId: '401692251430',
    projectId: 'church-register-qa',
    storageBucket: 'church-register-qa.firebasestorage.app',
    iosBundleId: 'com.church.register.churchRegister',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDqkm7YOkbWeHELY69JpC4Lv1SIlj3Jw2g',
    appId: '1:401692251430:web:e844e745bfe73e6de31de7',
    messagingSenderId: '401692251430',
    projectId: 'church-register-qa',
    authDomain: 'church-register-qa.firebaseapp.com',
    storageBucket: 'church-register-qa.firebasestorage.app',
    measurementId: 'G-8HGHY2V1FL',
  );
}
