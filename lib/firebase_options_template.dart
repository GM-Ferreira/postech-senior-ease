// Template for Firebase configuration.
// Copy this file as firebase_options.dart and replace the placeholders with your Firebase project values.
// Or run: flutterfire configure
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '{{FIREBASE_WEB_API_KEY}}',
    appId: '{{FIREBASE_WEB_APP_ID}}',
    messagingSenderId: '{{FIREBASE_MESSAGING_SENDER_ID}}',
    projectId: '{{FIREBASE_PROJECT_ID}}',
    authDomain: '{{FIREBASE_AUTH_DOMAIN}}',
    storageBucket: '{{FIREBASE_STORAGE_BUCKET}}',
    measurementId: '{{FIREBASE_MEASUREMENT_ID}}',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '{{FIREBASE_ANDROID_API_KEY}}',
    appId: '{{FIREBASE_ANDROID_APP_ID}}',
    messagingSenderId: '{{FIREBASE_MESSAGING_SENDER_ID}}',
    projectId: '{{FIREBASE_PROJECT_ID}}',
    storageBucket: '{{FIREBASE_STORAGE_BUCKET}}',
  );
}
