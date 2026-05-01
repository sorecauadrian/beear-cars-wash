import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? bookingId;
  final String? status;
  final bool sent;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.bookingId,
    this.status,
    required this.sent,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      bookingId: data['bookingId'] as String?,
      status: data['status'] as String?,
      sent: data['sent'] as bool? ?? false,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
