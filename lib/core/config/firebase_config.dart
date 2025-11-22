import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration and initialization
/// 
/// This handles Firebase initialization. Once you add the config files:
/// - android/app/google-services.json (or in dev/prod folders)
/// - ios/Runner/GoogleService-Info.plist
/// 
/// Firebase will automatically detect and use them.
class FirebaseConfig {
  FirebaseConfig._();

  /// Initialize Firebase
  /// 
  /// This will work automatically once you:
  /// 1. Add google-services.json to android/app/
  /// 2. Add GoogleService-Info.plist to ios/Runner/
  /// 
  /// For dev/prod flavors, you can extend this later.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      if (kDebugMode) {
      print('✅ Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
        print('📝 Make sure you have added the Firebase config files:');
        print('   - android/app/google-services.json');
        print('   - ios/Runner/GoogleService-Info.plist');
      }
      // Re-throw to prevent app from running without Firebase
      rethrow;
    }
  }
}

