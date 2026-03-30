// ignore_for_file: type=lint
// coverage:ignore-file

// This file is a placeholder for Firebase options.
// The Flutter app uses a Node.js backend for auth/data (not direct Firebase SDK).
// Firebase is initialized on the backend. This file exists to satisfy the
// Firebase.initializeApp() call in main.dart for Firebase Messaging.
//
// If you want to use Firebase directly from Flutter, replace this with the
// output of `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  // ⚠️  Replace these placeholder values with your real Firebase config
  // by running: flutterfire configure
  // or by copying from your Firebase console → Project Settings → Your app

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'onecampus-project',
    storageBucket: 'onecampus-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'onecampus-project',
    storageBucket: 'onecampus-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'onecampus-project',
    storageBucket: 'onecampus-project.appspot.com',
    iosBundleId: 'com.onecampus.app',
  );
}