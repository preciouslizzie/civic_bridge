import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase has not been configured for Web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase has not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrGIPBna5w04Xh0yPVivPsAG-OYsx41VY',
    appId: '1:185353254668:android:5ebe7d23a58192db0ffb29',
    messagingSenderId: '185353254668',
    projectId: 'civic-bridge-1d71f',
    storageBucket: 'civic-bridge-1d71f.firebasestorage.app',
  );
}