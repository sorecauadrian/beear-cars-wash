import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  FirebaseConfig._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _initialized = true;
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      _initialized = false;
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      rethrow;
    }
  }
}

