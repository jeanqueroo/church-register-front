import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/app_user_role.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
import '../models/supervisor_account.dart';

class SupervisorAssignmentService {
  SupervisorAssignmentService({
    FirebaseFirestore? firestore,
    LeaderService? leaderService,
  })  : _users = (firestore ?? FirebaseFirestore.instance).collection('users'),
        _leaderService = leaderService ?? LeaderService();

  final CollectionReference<Map<String, dynamic>> _users;
  final LeaderService _leaderService;

  Stream<List<SupervisorAccount>> watchSupervisors({String? churchId}) {
    return _users
        .where('roles', arrayContains: AppUserRole.supervisor)
        .snapshots()
        .asyncMap((snapshot) => _enrichSupervisors(snapshot.docs, churchId));
  }

  Future<List<SupervisorAccount>> fetchSupervisors({String? churchId}) async {
    final snapshot =
        await _users.where('roles', arrayContains: AppUserRole.supervisor).get();
    return _enrichSupervisors(snapshot.docs, churchId);
  }

  Stream<List<String>> watchSupervisedLeaderIds(String supervisorUid) {
    return _users.doc(supervisorUid).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      return SupervisorAccount.parseSupervisedLeaderIds(
        doc.data()?['supervisedLeaderIds'],
      );
    });
  }

  Future<List<String>> fetchSupervisedLeaderIds(String supervisorUid) async {
    final doc = await _users.doc(supervisorUid).get();
    if (!doc.exists) return [];
    return SupervisorAccount.parseSupervisedLeaderIds(
      doc.data()?['supervisedLeaderIds'],
    );
  }

  Future<void> saveSupervisedLeaders({
    required String supervisorUid,
    required List<String> leaderIds,
  }) {
    final uniqueIds = leaderIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList()
      ..sort();
    return _users.doc(supervisorUid).set(
      {
        'supervisedLeaderIds': uniqueIds,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<SupervisorAccount>> _enrichSupervisors(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String? churchId,
  ) async {
    final accounts = docs
        .map(SupervisorAccount.fromFirestore)
        .where((account) => account.matchesChurch(churchId))
        .toList();

    final leaderIds = accounts
        .map((account) => account.leaderId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final leaderNames = <String, String>{};
    for (final leaderId in leaderIds) {
      final leader = await _leaderService.fetchLeaderById(leaderId);
      final name = leader?.fullName.trim();
      if (name != null && name.isNotEmpty) {
        leaderNames[leaderId] = name;
      }
    }

    final enriched = accounts
        .map(
          (account) => account.copyWith(
            displayName: account.leaderId != null
                ? leaderNames[account.leaderId]
                : null,
          ),
        )
        .toList();
    enriched.sort((a, b) => a.displayLabel.compareTo(b.displayLabel));
    return enriched;
  }

  static String leaderLabel(ChurchLeader leader) {
    final parts = <String>[leader.fullName];
    if (leader.cellCode != null) {
      parts.add('Célula ${leader.cellCode}');
    }
    return parts.join(' · ');
  }

  static String messageFromException(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'No tienes permiso para asignar líderes a supervisores.';
        case 'unavailable':
          return 'Servicio no disponible. Revisa tu conexión.';
        default:
          return 'Error: ${e.message ?? e.code}';
      }
    }
    return 'Error inesperado. Intenta de nuevo.';
  }
}
