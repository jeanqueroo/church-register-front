import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_notification.dart';

class AdminNotificationService {
  AdminNotificationService({FirebaseFirestore? firestore})
      : _notifications = (firestore ?? FirebaseFirestore.instance)
            .collection('notifications');

  final CollectionReference<Map<String, dynamic>> _notifications;

  Stream<List<AdminNotification>> watchForUser(String userId) {
    return _notifications
        .where('recipientUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map(AdminNotification.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> watchUnreadCountForUser(String userId) {
    return watchForUser(userId).map(
      (list) => list.where((n) => !n.read).length,
    );
  }

  Future<void> markAsRead(String notificationId) {
    return _notifications.doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsReadForUser(String userId) async {
    final snapshot = await _notifications
        .where('recipientUserId', isEqualTo: userId)
        .get();

    final unread =
        snapshot.docs.where((doc) => doc.data()['read'] != true);
    if (unread.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
