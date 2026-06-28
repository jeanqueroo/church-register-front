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
        return androidProd;
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

   static const FirebaseOptions androidProd = FirebaseOptions(
    apiKey: 'AIzaSyAo3wSHVkCg_L02YoYbx9STr2k5Gr_Ic58',
    appId: '1:572729325735:android:00f7d42465810616b78382',
    messagingSenderId: '572729325735',
    projectId: 'church-register-stg',
    storageBucket: 'church-register-stg.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBC3NNfyb8xVTR1ayiCXHvkfDKgnPmTt-I',
    appId: '1:572729325735:ios:1e1ba0859930b06eb78382',
    messagingSenderId: '572729325735',
    projectId: 'church-register-stg',
    storageBucket: 'church-register-stg.firebasestorage.app',
    iosBundleId: 'com.church.register.manantial',
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
