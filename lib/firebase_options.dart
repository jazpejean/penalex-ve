import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    return android;
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.maybeGet("FIREBASE_API_KEY_ANDROID") ?? '',
        appId: dotenv.maybeGet("FIREBASE_APP_ID_ANDROID") ?? '',
        messagingSenderId: dotenv.maybeGet("FIREBASE_MESSAGING_SENDER_ID") ?? '',
        projectId: dotenv.maybeGet("FIREBASE_PROJECT_ID") ?? '',
        storageBucket: dotenv.maybeGet("FIREBASE_STORAGE_BUCKET") ?? '',
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.maybeGet("FIREBASE_API_KEY_WEB") ?? '',
        authDomain: dotenv.maybeGet("FIREBASE_AUTH_DOMAIN") ?? '',
        projectId: dotenv.maybeGet("FIREBASE_PROJECT_ID") ?? '',
        storageBucket: dotenv.maybeGet("FIREBASE_STORAGE_BUCKET") ?? '',
        messagingSenderId: dotenv.maybeGet("FIREBASE_MESSAGING_SENDER_ID") ?? '',
        appId: dotenv.maybeGet("FIREBASE_APP_ID_WEB") ?? '',
      );
}