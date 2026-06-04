import 'package:cloud_firestore/cloud_firestore.dart';

import '../../leaders/services/leader_service.dart';
import '../../members/models/church_member.dart';
import '../models/leader_notification.dart';

class LeaderNotificationService {
  LeaderNotificationService({
    FirebaseFirestore? firestore,
    LeaderService? leaderService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _leaderService = leaderService ?? LeaderService(),
        _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members');

  final FirebaseFirestore _firestore;
  final LeaderService _leaderService;
  final CollectionReference<Map<String, dynamic>> _members;

  CollectionReference<Map<String, dynamic>> _inbox(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// Escucha el buzón del líder: `users/{userId}/notifications`.
  Stream<List<LeaderNotification>> watchForUser(String userId) {
    return _inbox(userId).snapshots().map(_mapAndSortNotifications);
  }

  Stream<int> watchUnreadCountForUser(String userId) {
    return watchForUser(userId).map(
      (list) => list.where((n) => !n.read).length,
    );
  }

  /// Crea avisos para integrantes ya asignados que aún no tienen notificación.
  Future<void> syncAssignmentsForLeader({
    required String leaderId,
    required String recipientUserId,
  }) async {
    final membersSnapshot = await _members
        .where('assignedLeaderId', isEqualTo: leaderId)
        .get();
    if (membersSnapshot.docs.isEmpty) return;

    final inbox = _inbox(recipientUserId);
    final notificationsSnapshot = await inbox.get();
    final notifiedMemberIds = notificationsSnapshot.docs.map((doc) {
      final fromField = doc.data()['memberId'] as String?;
      return (fromField != null && fromField.isNotEmpty) ? fromField : doc.id;
    }).toSet();

    for (final memberDoc in membersSnapshot.docs) {
      if (notifiedMemberIds.contains(memberDoc.id)) continue;

      final member = ChurchMember.fromFirestore(memberDoc);
      await _createNotification(
        recipientUserId: recipientUserId,
        leaderId: leaderId,
        memberId: memberDoc.id,
        memberName: member.fullName,
      );
    }
  }

  Future<void> notifyMemberAssigned({
    required String leaderId,
    required String memberId,
    required String memberName,
  }) async {
    final recipientUserId = await _resolveRecipientUserId(leaderId);
    if (recipientUserId == null) return;

    await _createNotification(
      recipientUserId: recipientUserId,
      leaderId: leaderId,
      memberId: memberId,
      memberName: memberName,
    );
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) {
    return _inbox(userId).doc(notificationId).update({'read': true});
  }

  Future<void> markAllAsReadForUser(String userId) async {
    final snapshot = await _inbox(userId).get();
    final unread =
        snapshot.docs.where((doc) => doc.data()['read'] != true);
    if (unread.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Documento `users/{uid}/notifications/{memberId}` — solo `create`, sin leer el buzón ajeno.
  Future<void> _createNotification({
    required String recipientUserId,
    required String leaderId,
    required String memberId,
    required String memberName,
  }) async {
    await _inbox(recipientUserId).doc(memberId).set({
      'leaderId': leaderId,
      'memberId': memberId,
      'memberName': memberName,
      'type': 'member_assigned',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
