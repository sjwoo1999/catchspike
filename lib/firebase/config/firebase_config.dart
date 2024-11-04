// lib/firebase/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static String _getEnvOrThrow(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Environment variable $key is not set');
    }
    return value;
  }

  static FirebaseOptions get currentPlatform {
    try {
      if (kIsWeb) {
        throw UnsupportedError(
          'Firebase configuration is not available for web platform.',
        );
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return FirebaseOptions(
            apiKey: _getEnvOrThrow('FIREBASE_ANDROID_API_KEY'),
            appId: _getEnvOrThrow('FIREBASE_ANDROID_APP_ID'),
            messagingSenderId: _getEnvOrThrow('FIREBASE_MESSAGING_SENDER_ID'),
            projectId: _getEnvOrThrow('FIREBASE_PROJECT_ID'),
            storageBucket: _getEnvOrThrow('FIREBASE_STORAGE_BUCKET'),
          );
        case TargetPlatform.iOS:
          return FirebaseOptions(
            apiKey: _getEnvOrThrow('FIREBASE_IOS_API_KEY'),
            appId: _getEnvOrThrow('FIREBASE_IOS_APP_ID'),
            messagingSenderId: _getEnvOrThrow('FIREBASE_MESSAGING_SENDER_ID'),
            projectId: _getEnvOrThrow('FIREBASE_PROJECT_ID'),
            storageBucket: _getEnvOrThrow('FIREBASE_STORAGE_BUCKET'),
            iosBundleId: _getEnvOrThrow('FIREBASE_IOS_BUNDLE_ID'),
          );
        default:
          throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.',
          );
      }
    } catch (e) {
      print('Firebase configuration error: $e');
      rethrow;
    }
  }

  static String get functionUrl => _getEnvOrThrow('FIREBASE_FUNCTION_URL');
  static String get kakaoNativeKey => _getEnvOrThrow('KAKAO_NATIVE_APP_KEY');
  static String get kakaoJavaScriptKey =>
      dotenv.env['JAVASCRIPT_APP_KEY'] ?? '';
}
