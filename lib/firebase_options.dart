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
    apiKey: 'AIzaSyAd-9I9WKDu3HL3a86MLr0Jt6v7tjuHcNU',
    appId: '1:374770573112:android:29d96a8b8868cd39ef2bcd',
    messagingSenderId: '374770573112',
    projectId: 'church-register-pro',
    storageBucket: 'church-register-pro.firebasestorage.app',
  );
   static const FirebaseOptions androidProd = FirebaseOptions(
    apiKey: 'AIzaSyAd-9I9WKDu3HL3a86MLr0Jt6v7tjuHcNU',
    appId: '1:374770573112:android:29d96a8b8868cd39ef2bcd',
    messagingSenderId: '374770573112',
    projectId: 'church-register-pro',
    storageBucket: 'church-register-pro.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWqcXrfuXQnvoaNKLa2uND0sbi1Azn30g',
    appId: '1:374770573112:ios:853afd5681c31529ef2bcd',
    messagingSenderId: '374770573112',
    projectId: 'church-register-pro',
    storageBucket: 'church-register-pro.firebasestorage.app',
    iosBundleId: 'com.church.register.manantial',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDs443we-CoMcSI4N4fF6jxh4uQucM9dOU',
    appId: '1:374770573112:web:dbaa4c9d8fd8679eef2bcd',
    messagingSenderId: '374770573112',
    projectId: 'church-register-pro',
    authDomain: 'church-register-pro.firebaseapp.com',
    storageBucket: 'church-register-pro.firebasestorage.app',
    measurementId: 'G-T5HF3W5M8D',
  );
}
