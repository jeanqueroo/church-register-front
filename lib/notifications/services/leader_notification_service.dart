import 'package:cloud_firestore/cloud_firestore.dart';

import '../../leaders/services/leader_service.dart';
import '../../members/models/church_member.dart';
import '../models/leader_notification.dart';

class LeaderNotificationService {
  LeaderNotificationService({
    FirebaseFirestore? firestore,
    LeaderService? leaderService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _leaderServiceOverride = leaderService,
        _notifications = (firestore ?? FirebaseFirestore.instance)
            .collection('notifications'),
        _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members');

  final FirebaseFirestore _firestore;
  final LeaderService? _leaderServiceOverride;
  LeaderService? _leaderServiceLazy;
  final CollectionReference<Map<String, dynamic>> _notifications;
  final CollectionReference<Map<String, dynamic>> _members;

  LeaderService get _leaderService => _leaderServiceOverride ??
      (_leaderServiceLazy ??= LeaderService());

  /// Escucha notificaciones del líder por [leaderId] (coincide con `users.leaderId`).
  Stream<List<LeaderNotification>> watchForLeader(String leaderId) {
    return _notifications
        .where('leaderId', isEqualTo: leaderId)
        .snapshots()
        .map(_mapAndSortNotifications);
  }

  Stream<int> watchUnreadCountForLeader(String leaderId) {
    return watchForLeader(leaderId).map(
      (list) => list.where((n) => !n.read).length,
    );
  }

  /// Crea avisos para integrantes ya asignados que aún no tienen notificación.
  Future<void> syncAssignmentsForLeader(String leaderId) async {
    final membersSnapshot = await _members
        .where('assignedLeaderId', isEqualTo: leaderId)
        .get();
    if (membersSnapshot.docs.isEmpty) return;

    final notificationsSnapshot = await _notifications
        .where('leaderId', isEqualTo: leaderId)
        .get();
    final notifiedMemberIds = notificationsSnapshot.docs
        .map((doc) => doc.data()['memberId'] as String?)
        .whereType<String>()
        .toSet();

    final recipientUserId = await _resolveRecipientUserId(leaderId);

    for (final memberDoc in membersSnapshot.docs) {
      if (notifiedMemberIds.contains(memberDoc.id)) continue;

      final member = ChurchMember.fromFirestore(memberDoc);
      if (!member.isPastoralLeaderAssignment) continue;
      await _createNotification(
        leaderId: leaderId,
        memberId: memberDoc.id,
        memberName: member.fullName,
        recipientUserId: recipientUserId,
      );
    }
  }

  Future<void> notifyMemberAssigned({
    required String leaderId,
    required String memberId,
    required String memberName,
  }) async {
    if (await _hasNotification(leaderId: leaderId, memberId: memberId)) {
      return;
    }

    final recipientUserId = await _resolveRecipientUserId(leaderId);
    await _createNotification(
      leaderId: leaderId,
      memberId: memberId,
      memberName: memberName,
      recipientUserId: recipientUserId,
    );
  }

  Future<void> markAsRead(String notificationId) {
    return _notifications.doc(notificationId).update({
      'read': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsReadForLeader(String leaderId) async {
    final snapshot = await _notifications
        .where('leaderId', isEqualTo: leaderId)
        .get();

    final unread =
        snapshot.docs.where((doc) => doc.data()['read'] != true);
    if (unread.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {
        'read': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<bool> _hasNotification({
    required String leaderId,
    required String memberId,
  }) async {
    final snapshot = await _notifications
        .where('leaderId', isEqualTo: leaderId)
        .get();
    return snapshot.docs.any((doc) => doc.data()['memberId'] == memberId);
  }

  Future<void> _createNotification({
    required String leaderId,
    required String memberId,
    required String memberName,
    String? recipientUserId,
  }) async {
    final data = <String, dynamic>{
      'leaderId': leaderId,
      'memberId': memberId,
      'memberName': memberName,
      'type': 'member_assigned',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final uid = recipientUserId?.trim();
    if (uid != null && uid.isNotEmpty) {
      data['recipientUserId'] = uid;
    }

    await _notifications.add(data);
  }

  Future<String?> _resolveRecipientUserId(String leaderId) async {
    final leader = await _leaderService.fetchLeaderById(leaderId);
    final authUserId = leader?.authUserId?.trim();
    if (authUserId != null && authUserId.isNotEmpty) {
      return authUserId;
    }
    return null;
  }

  List<LeaderNotification> _mapAndSortNotifications(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = snapshot.docs.map(LeaderNotification.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(50).toList();
  }
}
