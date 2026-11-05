// File generated for thulirva_app with Project ID thulirva-e9697
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
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCADLy9kjEF0fVxm9M-T20BszCU0hL_LVU',
    appId: '1:240313377506:web:9bd83df5d78abf618974bb',
    messagingSenderId: '240313377506',
    projectId: 'thulirva-e9697',
    authDomain: 'thulirva-e9697.firebaseapp.com',
    storageBucket: 'thulirva-e9697.firebasestorage.app',
    measurementId: 'G-XRY0B58DT1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCW5QFy5lco2n9Sgnh2COTNqsMMMNe_6kg',
    appId: '1:240313377506:android:60893753795715008974bb',
    messagingSenderId: '240313377506',
    projectId: 'thulirva-e9697',
    storageBucket: 'thulirva-e9697.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC5nQtQ_-DcH3P3faNeK5Psn8_XPwRXOGc',
    appId: '1:240313377506:ios:25baae7e31f4ebb18974bb',
    messagingSenderId: '240313377506',
    projectId: 'thulirva-e9697',
    storageBucket: 'thulirva-e9697.firebasestorage.app',
    iosBundleId: 'com.thulirva.thulirvaApp',
  );
}

