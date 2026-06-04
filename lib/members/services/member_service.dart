import 'package:cloud_firestore/cloud_firestore.dart';

import '../../notifications/services/leader_notification_service.dart';
import '../models/church_member.dart';

class MemberService {
  MemberService({
    FirebaseFirestore? firestore,
    LeaderNotificationService? notificationService,
  })  : _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members'),
        _notificationService =
            notificationService ?? LeaderNotificationService();

  final CollectionReference<Map<String, dynamic>> _members;
  final LeaderNotificationService _notificationService;

  Stream<List<ChurchMember>> watchMembers() {
    return _members
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChurchMember.fromFirestore).toList(),
        );
  }

  Future<String> addMember(ChurchMember member) async {
    final ref = await _members.add(member.toMap());
    await _notifyLeaderIfAssigned(
      memberId: ref.id,
      member: member,
      previousLeaderId: null,
    );
    return ref.id;
  }

  Future<void> updateMember(
    ChurchMember member, {
    String? previousAssignedLeaderId,
  }) async {
    final id = member.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('El integrante debe tener id para actualizar');
    }
    await _members.doc(id).update(member.toMap());
    await _notifyLeaderIfAssigned(
      memberId: id,
      member: member,
      previousLeaderId: previousAssignedLeaderId,
    );
  }

  Future<ChurchMember?> fetchMemberById(String id) async {
    final doc = await _members.doc(id).get();
    if (!doc.exists) return null;
    return ChurchMember.fromFirestore(doc);
  }

  Future<void> _notifyLeaderIfAssigned({
    required String memberId,
    required ChurchMember member,
    required String? previousLeaderId,
  }) async {
    final leaderId = member.assignedLeaderId?.trim();
    if (leaderId == null || leaderId.isEmpty) return;
    if (previousLeaderId != null && previousLeaderId == leaderId) return;

    await _notificationService.notifyMemberAssigned(
      leaderId: leaderId,
      memberId: memberId,
      memberName: member.fullName,
    );
  }

  Future<void> deleteMember(String id) {
    return _members.doc(id).delete();
  }

  static String messageFromFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para esta operación.';
      case 'unavailable':
        return 'Firestore no está disponible. Revisa tu conexión.';
      case 'not-found':
        return 'El integrante ya no existe.';
      default:
        return 'Error al procesar la solicitud. Intenta de nuevo.';
    }
  }
}
