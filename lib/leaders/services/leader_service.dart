import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/app_user_role.dart';
import '../../auth/services/user_profile_service.dart';
import '../../core/search/firestore_search_text.dart';
import '../../l10n/app_localizations.dart';
import '../../members/services/member_service.dart';
import '../models/church_leader.dart';
import '../models/church_office.dart';
import '../models/leaders_page.dart';

class LeaderService {
  LeaderService({
    FirebaseFirestore? firestore,
    UserProfileService? userProfileService,
  })  : _leaders = (firestore ?? FirebaseFirestore.instance)
            .collection('leaders'),
        _userProfileService = userProfileService ?? UserProfileService();

  final CollectionReference<Map<String, dynamic>> _leaders;
  final UserProfileService _userProfileService;

  static const int leadersPageSize = 50;

  Stream<List<ChurchLeader>> watchLeaders({String? churchId}) {
    final query = churchId != null && churchId.isNotEmpty
        ? _leaders.where('churchId', isEqualTo: churchId)
        : _leaders.orderBy('registeredAt', descending: true);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(ChurchLeader.fromFirestore)
          .where((leader) => !leaderDocIndicatesAdmin(leader))
          .toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  /// Lista paginada de líderes (sin listener en tiempo real).
  Future<LeadersPage> fetchLeadersPage({
    String? churchId,
    String? searchQuery,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool hideBlocked = false,
    int limit = leadersPageSize,
  }) async {
    final trimmedSearch = normalizeSearchText(searchQuery ?? '');
    final hasSearch = trimmedSearch.isNotEmpty;

    if (hasSearch) {
      return _fetchLeadersClientSearchPage(
        churchId: churchId,
        trimmedSearch: trimmedSearch,
        hideBlocked: hideBlocked,
      );
    }

    Query<Map<String, dynamic>> query = _leaders;
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }
    if (hideBlocked) {
      query = query.where('isBlocked', isEqualTo: false);
    }

    query = query.orderBy('registeredAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit + 1).get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;

    return LeadersPage(
      leaders: await _excludeAdminAccounts(
        pageDocs.map(ChurchLeader.fromFirestore),
      ),
      hasMore: hasMore,
      lastDocument: pageDocs.isEmpty ? startAfter : pageDocs.last,
    );
  }

  /// Búsqueda en memoria: recorre líderes y filtra por nombre, teléfono, etc.
  Future<LeadersPage> _fetchLeadersClientSearchPage({
    String? churchId,
    required String trimmedSearch,
    required bool hideBlocked,
  }) async {
    final matches = <ChurchLeader>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      Query<Map<String, dynamic>> query = _leaders;
      if (churchId != null && churchId.isNotEmpty) {
        query = query.where('churchId', isEqualTo: churchId);
      }
      if (hideBlocked) {
        query = query.where('isBlocked', isEqualTo: false);
      }
      query = query.orderBy('registeredAt', descending: true);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.limit(leadersPageSize).get();
      if (snapshot.docs.isEmpty) break;

      for (final doc in snapshot.docs) {
        final leader = ChurchLeader.fromFirestore(doc);
        if (leader.matchesSearchQuery(trimmedSearch)) {
          matches.add(leader);
        }
      }

      cursor = snapshot.docs.last;
      if (snapshot.docs.length < leadersPageSize) break;
    }

    matches.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

    return LeadersPage(
      leaders: await _excludeAdminAccounts(matches),
      hasMore: false,
      lastDocument: null,
    );
  }

  /// Exportación o mapa: recorre todas las páginas del filtro activo.
  Future<List<ChurchLeader>> fetchAllLeadersForExport({
    String? churchId,
    String? searchQuery,
    bool hideBlocked = false,
  }) async {
    final all = <ChurchLeader>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      final page = await fetchLeadersPage(
        churchId: churchId,
        searchQuery: searchQuery,
        startAfter: cursor,
        hideBlocked: hideBlocked,
        limit: leadersPageSize,
      );
      all.addAll(page.leaders);
      if (!page.hasMore || page.lastDocument == null) break;
      cursor = page.lastDocument;
    }

    return all;
  }

  Future<int> fetchBlockedLeadersCount({String? churchId}) async {
    Query<Map<String, dynamic>> query =
        _leaders.where('isBlocked', isEqualTo: true);
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<String> addLeader(ChurchLeader leader) async {
    final doc = await _leaders.add(leader.toMap());
    return doc.id;
  }

  Future<String> addLeaderWithMember({
    required ChurchLeader leader,
    required String registeredBy,
    String? existingMemberId,
    MemberService? memberService,
  }) async {
    final leaderId = await addLeader(leader);
    await (memberService ?? MemberService()).syncMemberForPromotedLeader(
      leader: leader,
      leaderId: leaderId,
      registeredBy: registeredBy,
      existingMemberId: existingMemberId,
    );
    return leaderId;
  }

  Future<void> updateLeader(ChurchLeader leader) {
    final id = leader.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('El líder debe tener id para actualizar');
    }
    return _leaders.doc(id).set(leader.toMap(), SetOptions(merge: true));
  }

  Future<void> updateLeaderPhotoUrl({
    required String leaderId,
    required String? photoUrl,
  }) {
    final trimmed = photoUrl?.trim() ?? '';
    return _leaders.doc(leaderId).set(
      {
        if (trimmed.isNotEmpty)
          'photoUrl': trimmed
        else
          'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
    await _leaders.doc(id).update({
      'isBlocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    return roles.any(_pastoralAssignmentRoles.contains);
  }

  static bool leaderDocIndicatesAdmin(ChurchLeader leader) {
    final docRoles = leader.appRoles;
    if (docRoles == null || docRoles.isEmpty) return false;
    return AppUserRole.hasAdminAccess(docRoles);
  }

  Future<List<ChurchLeader>> _excludeAdminAccounts(
    Iterable<ChurchLeader> leaders,
  ) async {
    final list = leaders.toList();
    final result = <ChurchLeader>[];
    final needsLookup = <ChurchLeader>[];

    for (final leader in list) {
      final docRoles = leader.appRoles;
      if (docRoles != null && docRoles.isNotEmpty) {
        if (!AppUserRole.hasAdminAccess(docRoles)) {
          result.add(leader);
        }
        continue;
      }

      final uid = leader.authUserId?.trim();
      if (uid == null || uid.isEmpty) {
        result.add(leader);
        continue;
      }
      needsLookup.add(leader);
    }

    if (needsLookup.isEmpty) return result;

    final profiles = await Future.wait(
      needsLookup.map((leader) {
        final uid = leader.authUserId!.trim();
        return _userProfileService.fetchProfileDoc(uid);
      }),
    );

    for (var i = 0; i < needsLookup.length; i++) {
      final leader = needsLookup[i];
      final doc = profiles[i];
      if (doc == null) {
        result.add(leader);
        continue;
      }
      final roles = AppUserRole.parseList(doc.data()?['roles']);
      if (!AppUserRole.hasAdminAccess(roles)) {
        result.add(leader);
      }
    }

    return result;
  }

  /// Cuenta en `users` con rol líder o supervisor (asignación pastoral / titular de célula).
  Future<bool> hasPastoralAssignmentAppRole(ChurchLeader leader) async {
    final docRoles = leader.appRoles;
    if (docRoles != null && docRoles.isNotEmpty) {
      return rolesAllowPastoralAssignment(docRoles);
    }

    final authUserId = leader.authUserId?.trim();
    if (authUserId == null || authUserId.isEmpty) {
      return isLeaderOrSupervisorInCollection(leader);
    }

    try {
      final doc = await _userProfileService.fetchProfileDoc(authUserId);
      if (doc == null) return isLeaderOrSupervisorInCollection(leader);

      final data = doc.data() ?? {};
      final roles = AppUserRole.parseList(data['roles']);
      final rolesFinal =
          roles.isNotEmpty ? roles : AppUserRole.parseList(data['role']);
      if (rolesAllowPastoralAssignment(rolesFinal)) return true;
      return isLeaderOrSupervisorInCollection(leader);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return isLeaderOrSupervisorInCollection(leader);
      }
      rethrow;
    }
  }

  static bool isLeaderOrSupervisorInCollection(ChurchLeader leader) {
    final roles = leader.appRoles;
    if (roles != null && roles.isNotEmpty) {
      return rolesAllowPastoralAssignment(roles);
    }
    return leader.churchOffice == ChurchOffice.lideres;
  }

  /// Líderes y supervisores de la iglesia según la colección `leaders`.
  Future<int> countLeadersAndSupervisorsInChurch({String? churchId}) async {
    var leaders = (await fetchAllLeaders(churchId: churchId))
        .where((leader) => !leader.isBlocked)
        .toList();
    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      leaders = leaders
          .where((leader) => leader.belongsToChurch(normalizedChurchId))
          .toList();
    }
    return leaders.where(isLeaderOrSupervisorInCollection).length;
  }

  Future<int> countLeadersWithPastoralRole({String? churchId}) async {
    var leaders = (await fetchAllLeaders(churchId: churchId))
        .where((leader) => !leader.isBlocked)
        .toList();
    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      leaders = leaders
          .where((leader) => leader.belongsToChurch(normalizedChurchId))
          .toList();
    }

    var count = 0;
    for (final leader in leaders) {
      if (await hasPastoralAssignmentAppRole(leader)) {
        count++;
      }
    }
    return count;
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

  /// Asegura que [leaderId] esté en la lista (p. ej. líder actual de la célula al editar).
  Future<List<ChurchLeader>> ensureLeaderInList({
    required List<ChurchLeader> leaders,
    required String leaderId,
    String? churchId,
  }) async {
    final id = leaderId.trim();
    if (id.isEmpty || leaders.any((leader) => leader.id == id)) {
      return leaders;
    }

    final leader = await fetchLeaderById(id);
    if (leader == null || leader.isBlocked) return leaders;
    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId != null &&
        normalizedChurchId.isNotEmpty &&
        !leader.belongsToChurch(normalizedChurchId)) {
      return leaders;
    }

    final merged = [...leaders, leader]
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return merged;
  }

  /// Líderes elegibles como titular de célula (excluye ocupados en otra célula).
  Future<List<ChurchLeader>> fetchLeadersForCellLeaderPicker({
    required String? churchId,
    required Set<String> busyLeaderIds,
    String? ensureLeaderId,
  }) async {
    final assignable = await fetchAssignableLeaders(churchId: churchId);
    var list = assignable.where((leader) {
      final id = leader.id?.trim();
      if (id == null || id.isEmpty) return false;
      return !busyLeaderIds.contains(id);
    }).toList();

    final ensureId = ensureLeaderId?.trim();
    if (ensureId != null && ensureId.isNotEmpty) {
      list = await ensureLeaderInList(
        leaders: list,
        leaderId: ensureId,
        churchId: churchId,
      );
    }
    return list;
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
