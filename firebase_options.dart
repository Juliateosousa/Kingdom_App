import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Se quiser tratar Web depois, pode colocar aqui um if (kIsWeb)
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      // Se você um dia rodar em macOS/Windows/Linux, decide depois:
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArN9qturAPfxsQC4X-G7_7lk0wp6tEg8c',
    appId: '1:383599694014:android:ef1c2711bc0e993fd34eef',
    messagingSenderId: '383599694014',
    projectId: 'kingdomapp-52496',
    storageBucket: 'kingdomapp-52496.firebasestorage.app',
  );

  // ANDROID – igual ao seu

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNe7LCu9FtmJfzwzm_dfa3Ygd7i4rZ0W8',
    appId: '1:383599694014:ios:bca2fa8ff1ad6a83d34eef',
    messagingSenderId: '383599694014',
    projectId: 'kingdomapp-52496',
    storageBucket: 'kingdomapp-52496.firebasestorage.app',
    iosBundleId: 'com.example.kingdomApp',
  );
}