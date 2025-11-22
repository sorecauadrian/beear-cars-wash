import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';

/// Top-level function for handling background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
  // Background messages are handled here
  // You can perform tasks like updating local database, etc.
}

/// Notification service for handling FCM push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentUserId;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('Notification permission status: ${settings.authorizationStatus}');
      }

      // Initialize local notifications for Android foreground notifications
      // Note: This requires a full rebuild (not hot reload) to work
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      try {
        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Local notifications initialization failed (this is OK for now): $e');
          print('💡 Note: Local notifications require a full rebuild. For MVP, FCM will still work.');
        }
        // Continue without local notifications - FCM will still work
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get and save FCM token
      await _saveFCMToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveFCMTokenToFirestore(newToken);
      });

      _initialized = true;

      if (kDebugMode) {
        print('✅ Notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize notification service: $e');
      }
    }
  }

  /// Set current user ID for token storage
  void setUserId(String userId) {
    _currentUserId = userId;
    _saveFCMToken();
  }

  /// Clear user ID on logout
  void clearUserId() {
    _currentUserId = null;
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    }

    // Show local notification for foreground messages
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Beear Cars Wash',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap (app in background or terminated)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.messageId}');
      print('Data: ${message.data}');
    }

    // Handle navigation based on notification data
    // For now, we'll just log it. Navigation can be added later.
    final bookingId = message.data['bookingId'];
    final status = message.data['status'];

    if (kDebugMode) {
      print('Booking ID: $bookingId, Status: $status');
    }
  }

  /// Show local notification (for foreground messages on Android)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'beear_cars_wash_channel',
        'Beear Cars Wash Notifications',
        channelDescription: 'Notifications for booking status updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to show local notification: $e');
      }
      // Continue - FCM notifications will still work in background
    }
  }

  /// Handle notification tap (local notifications)
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Local notification tapped: ${response.payload}');
    }
    // Handle navigation if needed
  }

  /// Get and save FCM token
  Future<void> _saveFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        await _saveFCMTokenToFirestore(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
    }
  }

  /// Save FCM token to Firestore user document
  Future<void> _saveFCMTokenToFirestore(String token) async {
    if (_currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(_currentUserId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save FCM token: $e');
      }
    }
  }

  /// Get FCM token (for testing)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

