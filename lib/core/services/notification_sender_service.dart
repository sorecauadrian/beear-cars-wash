import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/bookings/data/models/booking_model.dart';
import '../../core/constants/firestore_paths.dart';

/// Service to send push notifications when booking status changes
/// 
/// For MVP, we'll send notifications directly from the app.
/// In production, you might want to use Cloud Functions for this.
class NotificationSenderService {
  static final NotificationSenderService _instance =
      NotificationSenderService._internal();
  factory NotificationSenderService() => _instance;
  NotificationSenderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to company admin when booking status changes
  Future<void> sendBookingStatusNotification({
    required BookingModel booking,
    required BookingStatus oldStatus,
    required BookingStatus newStatus,
  }) async {
    try {
      // Get company admin user for this booking
      final companyAdmin = await _getCompanyAdmin(booking.companyId);
      if (companyAdmin == null) {
        if (kDebugMode) {
          print('No company admin found for company ${booking.companyId}');
        }
        return;
      }

      // Get FCM token
      final fcmToken = companyAdmin['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        if (kDebugMode) {
          print('No FCM token found for company admin');
        }
        return;
      }

      // Prepare notification message
      final title = _getNotificationTitle(newStatus);
      final body = _getNotificationBody(booking, newStatus);

      // For MVP, we'll use Firestore to trigger a Cloud Function
      // or send via Firebase Admin SDK from a backend service.
      // Since we don't have Cloud Functions set up, we'll store the notification
      // in Firestore and it can be sent via a Cloud Function later.
      // 
      // For now, we'll create a notification document that can be processed
      // by a Cloud Function or backend service.
      await _createNotificationDocument(
        userId: companyAdmin.id,
        fcmToken: fcmToken,
        title: title,
        body: body,
        bookingId: booking.id,
        status: newStatus.toString(),
      );

      if (kDebugMode) {
        print('✅ Notification queued for company admin');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send notification: $e');
      }
    }
  }

  /// Get company admin user for a company
  Future<DocumentSnapshot?> _getCompanyAdmin(String companyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestorePaths.users)
          .where('companyId', isEqualTo: companyId)
          .where('role', isEqualTo: 'company_admin')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting company admin: $e');
      }
      return null;
    }
  }

  /// Create notification document in Firestore
  /// This can be processed by a Cloud Function to send the actual notification
  Future<void> _createNotificationDocument({
    required String userId,
    required String fcmToken,
    required String title,
    required String body,
    required String bookingId,
    required String status,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'bookingId': bookingId,
        'status': status,
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification document: $e');
      }
    }
  }

  /// Get notification title based on status
  String _getNotificationTitle(BookingStatus status) {
    switch (status) {
      case BookingStatus.accepted:
        return 'Booking Accepted';
      case BookingStatus.rejected:
        return 'Booking Rejected';
      case BookingStatus.inProgress:
        return 'Wash In Progress';
      case BookingStatus.done:
        return 'Wash Completed';
      case BookingStatus.requested:
        return 'New Booking Request';
    }
  }

  /// Get notification body based on booking and status
  String _getNotificationBody(BookingModel booking, BookingStatus status) {
    final date = booking.date;
    final time = booking.slotStart;
    
    switch (status) {
      case BookingStatus.accepted:
        return 'Your booking for $date at $time has been accepted.';
      case BookingStatus.rejected:
        return 'Your booking for $date at $time has been rejected.';
      case BookingStatus.inProgress:
        return 'Your car wash for $date at $time has started.';
      case BookingStatus.done:
        return 'Your car wash for $date at $time has been completed.';
      case BookingStatus.requested:
        return 'Your booking for $date at $time has been submitted.';
    }
  }
}

