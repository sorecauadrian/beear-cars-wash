import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';

final userNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.id)
          .snapshots()
          .map((snapshot) {
        final docs = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
        docs.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return docs;
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
