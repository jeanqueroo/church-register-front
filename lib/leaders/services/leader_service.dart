import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/services/user_profile_service.dart';
import '../models/church_leader.dart';

class LeaderService {
  LeaderService({
    FirebaseFirestore? firestore,
    UserProfileService? userProfileService,
  })  : _leaders = (firestore ?? FirebaseFirestore.instance)
            .collection('leaders'),
        _userProfileService = userProfileService ?? UserProfileService();

  final CollectionReference<Map<String, dynamic>> _leaders;
  final UserProfileService _userProfileService;

  Stream<List<ChurchLeader>> watchLeaders() {
    return _leaders
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChurchLeader.fromFirestore).toList(),
        );
  }

  Future<String> addLeader(ChurchLeader leader) async {
    final doc = await _leaders.add(leader.toMap());
    return doc.id;
  }

  Future<void> updateLeader(ChurchLeader leader) {
    final id = leader.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('El líder debe tener id para actualizar');
    }
    return _leaders.doc(id).set(leader.toMap(), SetOptions(merge: true));
  }

  Future<ChurchLeader?> fetchLeaderByAuthUserId(String authUserId) async {
    final snapshot = await _leaders
        .where('authUserId', isEqualTo: authUserId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ChurchLeader.fromFirestore(snapshot.docs.first);
  }

  Future<void> deleteLeader(String id) {
    return _leaders.doc(id).delete();
  }

  Future<ChurchLeader?> fetchLeaderById(String id) async {
    final doc = await _leaders.doc(id).get();
    if (!doc.exists) return null;
    return ChurchLeader.fromFirestore(doc);
  }

  Future<List<ChurchLeader>> fetchAllLeaders() async {
    final snapshot = await _leaders.get();
    return snapshot.docs.map(ChurchLeader.fromFirestore).toList();
  }

  /// Solo fichas con rol Líder en la app (`acceptsMemberAssignments` o `users.roles`).
  Future<List<ChurchLeader>> fetchAssignableLeaders({
    Set<String>? restrictToIds,
  }) async {
    final leaderRoleIds = await _resolveLeaderRoleDocumentIds();
    final all = await fetchAllLeaders();
    var leaders = all
        .where((l) => _hasLeaderRoleForAssignment(l, leaderRoleIds))
        .toList();
    if (restrictToIds != null) {
      leaders = leaders
          .where((l) => l.id != null && restrictToIds.contains(l.id))
          .toList();
    }
    leaders.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return leaders;
  }

  Future<Set<String>> _resolveLeaderRoleDocumentIds() async {
    try {
      return await _userProfileService.fetchLeaderDocumentIdsWithLeaderRole();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return {};
      }
      rethrow;
    }
  }

  bool _hasLeaderRoleForAssignment(
    ChurchLeader leader,
    Set<String> leaderRoleDocIds,
  ) {
    final id = leader.id;
    if (id == null || id.isEmpty) return false;
    if (leader.acceptsMemberAssignments == true) return true;
    if (leader.acceptsMemberAssignments == false) return false;
    return leaderRoleDocIds.contains(id);
  }

  static String messageFromFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para esta operación.';
      case 'unavailable':
        return 'Firestore no está disponible. Revisa tu conexión.';
      case 'not-found':
        return 'El líder ya no existe.';
      default:
        return 'Error al procesar la solicitud. Intenta de nuevo.';
    }
  }
}
