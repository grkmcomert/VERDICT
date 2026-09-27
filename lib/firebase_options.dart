import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdyv-xstgBuaM2vcPNrU-bTdj5uqHh9ys',
    appId: '1:313253439679:android:6e65a02742107868943e0a',
    messagingSenderId: '313253439679',
    projectId: 'unfollowerscurrent',
    storageBucket: 'unfollowerscurrent.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC7wRwMzF8a_6SdJjice6aprJ2kdedBmL4',
    appId: '1:313253439679:ios:9304d42e9e2b0c9a943e0a',
    messagingSenderId: '313253439679',
    projectId: 'unfollowerscurrent',
    storageBucket: 'unfollowerscurrent.firebasestorage.app',
    iosBundleId: 'com.grkmcomert.unfollowerscurrent',
  );
}
