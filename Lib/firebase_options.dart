//This is just a base you use the comands to configure the firebase this file will be created automatically
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
    apiKey: 'Your apiKey',
    appId: 'Your appId',
    messagingSenderId: 'Your messagingSenderId',
    projectId: 'Your Project ID',
    storageBucket: 'Your project storageBucket',
  );

  // ANDROID – igual ao seu

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'Your apiKey',
    appId: 'Your appId',
    messagingSenderId: 'Your messagingSenderId',
    projectId: 'Your Project ID',
    storageBucket: 'Your project storageBucket',
    iosBundleId: 'Your iosBundleId',
  );
}
