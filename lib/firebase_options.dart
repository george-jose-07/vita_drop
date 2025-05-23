// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'your api key',
    appId: '1:601492668856:web:49165343e3798fa811cf4d',
    messagingSenderId: '601492668856',
    projectId: 'vita-drop-17',
    authDomain: 'vita-drop-17.firebaseapp.com',
    storageBucket: 'vita-drop-17.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your api key',
    appId: '1:601492668856:android:59dbfc18b6fcc17e11cf4d',
    messagingSenderId: '601492668856',
    projectId: 'vita-drop-17',
    storageBucket: 'vita-drop-17.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your api key',
    appId: '1:601492668856:ios:5e8c6c9e78aea51911cf4d',
    messagingSenderId: '601492668856',
    projectId: 'vita-drop-17',
    storageBucket: 'vita-drop-17.firebasestorage.app',
    iosClientId: '601492668856-2k861ojpr8bkfha2ium66h75o4ees5oc.apps.googleusercontent.com',
    iosBundleId: 'com.example.vitaDrop',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your api key',
    appId: '1:601492668856:ios:5e8c6c9e78aea51911cf4d',
    messagingSenderId: '601492668856',
    projectId: 'vita-drop-17',
    storageBucket: 'vita-drop-17.firebasestorage.app',
    iosClientId: '601492668856-2k861ojpr8bkfha2ium66h75o4ees5oc.apps.googleusercontent.com',
    iosBundleId: 'com.example.vitaDrop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your api key',
    appId: '1:601492668856:web:15873100962aeb6411cf4d',
    messagingSenderId: '601492668856',
    projectId: 'vita-drop-17',
    authDomain: 'vita-drop-17.firebaseapp.com',
    storageBucket: 'vita-drop-17.firebasestorage.app',
  );

}
