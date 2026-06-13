import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/app_user_role.dart';
import '../../auth/services/user_profile_service.dart';
import '../../l10n/app_localizations.dart';
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

  Stream<List<ChurchLeader>> watchLeaders({String? churchId}) {
    final query = churchId != null && churchId.isNotEmpty
        ? _leaders.where('churchId', isEqualTo: churchId)
        : _leaders.orderBy('registeredAt', descending: true);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ChurchLeader.fromFirestore).toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
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

  Future<void> setLeaderBlocked({
    required String id,
    required bool blocked,
    String? authUserId,
    required String updatedBy,
  }) async {
    await _leaders.doc(id).update({'isBlocked': blocked});
    final uid = authUserId?.trim();
    if (uid != null && uid.isNotEmpty) {
      await _userProfileService.setUserBlocked(
        uid: uid,
        blocked: blocked,
        updatedBy: updatedBy,
      );
    }
  }

  Future<ChurchLeader?> fetchLeaderById(String id) async {
    final doc = await _leaders.doc(id).get();
    if (!doc.exists) return null;
    return ChurchLeader.fromFirestore(doc);
  }

  Future<List<ChurchLeader>> fetchAllLeaders({String? churchId}) async {
    final snapshot = churchId != null && churchId.isNotEmpty
        ? await _leaders.where('churchId', isEqualTo: churchId).get()
        : await _leaders.get();
    return snapshot.docs.map(ChurchLeader.fromFirestore).toList();
  }

  static const _pastoralAssignmentRoles = {
    AppUserRole.leader,
    AppUserRole.supervisor,
  };

  static bool rolesAllowPastoralAssignment(List<String> roles) {
    if (roles.contains(AppUserRole.registrar)) return false;
    return roles.any(_pastoralAssignmentRoles.contains);
  }

  /// Cuenta en `users` con rol líder o supervisor (asignación pastoral).
  Future<bool> hasPastoralAssignmentAppRole(ChurchLeader leader) async {
    final docRoles = leader.appRoles;
    if (docRoles != null && docRoles.isNotEmpty) {
      return rolesAllowPastoralAssignment(docRoles);
    }

    final authUserId = leader.authUserId?.trim();
    if (authUserId == null || authUserId.isEmpty) return false;

    try {
      final doc = await _userProfileService.fetchProfileDoc(authUserId);
      if (doc == null) return false;

      final data = doc.data() ?? {};
      final roles = AppUserRole.parseList(data['roles']);
      final rolesFinal =
          roles.isNotEmpty ? roles : AppUserRole.parseList(data['role']);
      if (rolesFinal.contains(AppUserRole.registrar)) return false;
      return rolesAllowPastoralAssignment(rolesFinal);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
  }

  Future<List<ChurchLeader>> fetchAssignableLeaders({String? churchId}) async {
    var leaders = (await fetchAllLeaders(churchId: churchId))
        .where((leader) => !leader.isBlocked)
        .toList();
    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      leaders = leaders
          .where((leader) => leader.belongsToChurch(normalizedChurchId))
          .toList();
    }

    final results = await Future.wait(
      leaders.map((leader) async {
        if (await hasPastoralAssignmentAppRole(leader)) return leader;
        return null;
      }),
    );
    return results.whereType<ChurchLeader>().toList();
  }

  static String messageFromFirestoreException(
    FirebaseException e,
    AppLocalizations l10n,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return l10n.firestorePermissionDenied;
      case 'unavailable':
        return l10n.firestoreUnavailable;
      case 'not-found':
        return l10n.firestoreLeaderNotFound;
      default:
        return l10n.firestoreGenericError;
    }
  }
}
