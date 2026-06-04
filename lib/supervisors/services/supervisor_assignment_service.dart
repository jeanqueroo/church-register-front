import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/app_user_role.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
import '../models/supervisor_account.dart';

class SupervisorAssignmentService {
  SupervisorAssignmentService({FirebaseFirestore? firestore})
      : _users = (firestore ?? FirebaseFirestore.instance).collection('users');

  final CollectionReference<Map<String, dynamic>> _users;

  Stream<List<String>> watchSupervisedLeaderIds(String supervisorUid) {
    return _users.doc(supervisorUid).snapshots().map((doc) {
      return _parseLeaderIds(doc.data()?['supervisedLeaderIds']);
    });
  }

  Future<Set<String>> fetchSupervisedLeaderIdSet(String supervisorUid) async {
    final ids = await watchSupervisedLeaderIds(supervisorUid).first;
    return ids.toSet();
  }

  /// Cartera del supervisor sin su propia ficha (no aparece “asignado a sí mismo”).
  Future<Set<String>> fetchSupervisedLeaderIdSetExcludingSelf(
    String supervisorUid,
  ) async {
    final ids = await fetchSupervisedLeaderIdSet(supervisorUid);
    final ownLeaderId = await _fetchOwnLeaderIdIfLeaderRole(supervisorUid);
    if (ownLeaderId != null) {
      ids.remove(ownLeaderId);
    }
    return ids;
  }

  /// Id en `leaders` del supervisor cuando su cuenta también tiene rol `leader`.
  Future<String?> _fetchOwnLeaderIdIfLeaderRole(String supervisorUid) async {
    final doc = await _users.doc(supervisorUid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    final roles = AppUserRole.parseList(data['roles']);
    if (!roles.contains(AppUserRole.leader)) return null;
    final leaderId = data['leaderId'] as String?;
    if (leaderId == null || leaderId.isEmpty) return null;
    return leaderId;
  }

  /// Líderes asignados al supervisor que además tienen rol `leader`.
  ///
  /// Con [includeOwnLeaderFicha] (p. ej. al registrar creyentes), incluye la
  /// ficha propia aunque no esté en `supervisedLeaderIds`.
  Future<List<ChurchLeader>> fetchAssignedLeaders(
    String supervisorUid, {
    LeaderService? leaderService,
    bool includeOwnLeaderFicha = false,
  }) async {
    var ids = await fetchSupervisedLeaderIdSetExcludingSelf(supervisorUid);
    if (includeOwnLeaderFicha) {
      final ownLeaderId = await _fetchOwnLeaderIdIfLeaderRole(supervisorUid);
      if (ownLeaderId != null) {
        ids = Set<String>.from(ids)..add(ownLeaderId);
      }
    }
    final service = leaderService ?? LeaderService();
    return service.fetchAssignableLeaders(restrictToIds: ids);
  }

  Future<List<SupervisorAccount>> fetchSupervisorAccounts() async {
    final snapshot = await _users
        .where('roles', arrayContains: AppUserRole.supervisor)
        .get();

    final accounts = snapshot.docs.map(_supervisorFromDoc).toList();
    accounts.sort(
      (a, b) => a.displayLabel.toLowerCase().compareTo(
            b.displayLabel.toLowerCase(),
          ),
    );
    return accounts;
  }

  /// A qué supervisor está asignado cada líder (id de documento en `leaders`).
  Future<Map<String, String>> fetchLeaderToSupervisorMap() async {
    final supervisors = await fetchSupervisorAccounts();
    final map = <String, String>{};
    for (final supervisor in supervisors) {
      for (final leaderId in supervisor.supervisedLeaderIds) {
        map.putIfAbsent(leaderId, () => supervisor.uid);
      }
    }
    return map;
  }

  /// Líderes con rol Líder que el [supervisorUid] puede asignar o ya tiene.
  Future<List<ChurchLeader>> fetchLeadersForSupervisorAssignment({
    required String supervisorUid,
    LeaderService? leaderService,
  }) async {
    final service = leaderService ?? LeaderService();
    final assignable = await service.fetchAssignableLeaders();
    final ownerMap = await fetchLeaderToSupervisorMap();

    return assignable.where((leader) {
      final id = leader.id;
      if (id == null || id.isEmpty) return false;
      final owner = ownerMap[id];
      return owner == null || owner == supervisorUid;
    }).toList();
  }

  Future<void> setSupervisedLeaderIds({
    required String supervisorUid,
    required List<String> leaderIds,
  }) async {
    final leaderService = LeaderService();
    final assignable = await leaderService.fetchAssignableLeaders();
    final allowedIds = assignable.map((l) => l.id).whereType<String>().toSet();
    final validLeaderIds =
        leaderIds.where(allowedIds.contains).toList()..sort();

    final supervisors = await fetchSupervisorAccounts();
    final batch = _users.firestore.batch();
    final now = FieldValue.serverTimestamp();
    final assignedSet = validLeaderIds.toSet();


    for (final supervisor in supervisors) {
      final ref = _users.doc(supervisor.uid);
      if (supervisor.uid == supervisorUid) {
        batch.set(
          ref,
          {
            'supervisedLeaderIds': validLeaderIds,
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
        continue;
      }

      final othersLeaders = supervisor.supervisedLeaderIds
          .where((id) => !assignedSet.contains(id))
          .toList();
      if (othersLeaders.length != supervisor.supervisedLeaderIds.length) {
        batch.set(
          ref,
          {
            'supervisedLeaderIds': othersLeaders,
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }

  SupervisorAccount _supervisorFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SupervisorAccount(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String?,
      supervisedLeaderIds: _parseLeaderIds(data['supervisedLeaderIds']),
    );
  }

  List<String> _parseLeaderIds(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  static String messageFromFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para esta operación. '
            'Confirma que tu usuario en Firestore (colección users) tiene '
            'roles admin y/o supervisor, y publica firestore.rules '
            '(firebase deploy --only firestore:rules).';
      case 'unavailable':
        return 'Firestore no está disponible. Revisa tu conexión.';
      default:
        return 'Error al guardar las asignaciones. Intenta de nuevo.';
    }
  }
}
