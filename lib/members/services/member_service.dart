import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cells/cell_leader_gender.dart';
import '../../cells/cell_member_capacity.dart';
import '../../cells/models/church_cell.dart';
import '../../core/models/leader_gender.dart';
import '../../core/search/firestore_search_text.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/services/cell_capacity_notification_service.dart';
import '../../notifications/services/leader_notification_service.dart';
import '../models/church_member.dart';
import '../models/member_assignment_kind.dart';
import '../models/members_page.dart';
import '../../cells/models/cell_attendance_record.dart';
import '../../cells/models/cell_helper.dart';

class MemberService {
  MemberService({
    FirebaseFirestore? firestore,
    LeaderNotificationService? notificationService,
    CellCapacityNotificationService? capacityNotificationService,
  })  : _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members'),
        _notificationService =
            notificationService ?? LeaderNotificationService(),
        _capacityNotificationService =
            capacityNotificationService ?? CellCapacityNotificationService();

  final CollectionReference<Map<String, dynamic>> _members;
  final LeaderNotificationService _notificationService;
  final CellCapacityNotificationService _capacityNotificationService;

  static const int membersPageSize = 50;

  /// Presente en más de esta cantidad de reuniones de célula → deja de ser nuevo creyente.
  static const int cellPresentAttendancesToGraduateNewBeliever = 3;

  Stream<List<ChurchMember>> watchMembers({String? churchId}) {
    final query = churchId != null && churchId.isNotEmpty
        ? _members.where('churchId', isEqualTo: churchId)
        : _members.orderBy('registeredAt', descending: true);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ChurchMember.fromFirestore).toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  /// Lista paginada de creyentes (sin listener en tiempo real).
  Future<MembersPage> fetchMembersPage({
    String? churchId,
    String? searchQuery,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool newBelieversOnly = false,
    int limit = membersPageSize,
  }) async {
    final trimmedSearch = normalizeSearchText(searchQuery ?? '');
    final hasSearch = trimmedSearch.isNotEmpty;

    if (hasSearch) {
      return _fetchMembersClientSearchPage(
        churchId: churchId,
        trimmedSearch: trimmedSearch,
        newBelieversOnly: newBelieversOnly,
      );
    }

    Query<Map<String, dynamic>> query = _members;
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }
    if (newBelieversOnly) {
      query = query.where('isNewBeliever', isEqualTo: true);
    }

    query = query.orderBy('registeredAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit + 1).get();
    final docs = snapshot.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;

    return MembersPage(
      members: pageDocs.map(ChurchMember.fromFirestore).toList(),
      hasMore: hasMore,
      lastDocument: pageDocs.isEmpty ? startAfter : pageDocs.last,
    );
  }

  /// Búsqueda en memoria: recorre creyentes y filtra por nombre, apellido, teléfono, etc.
  Future<MembersPage> _fetchMembersClientSearchPage({
    String? churchId,
    required String trimmedSearch,
    required bool newBelieversOnly,
  }) async {
    final matches = <ChurchMember>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      Query<Map<String, dynamic>> query = _members;
      if (churchId != null && churchId.isNotEmpty) {
        query = query.where('churchId', isEqualTo: churchId);
      }
      if (newBelieversOnly) {
        query = query.where('isNewBeliever', isEqualTo: true);
      }
      query = query.orderBy('registeredAt', descending: true);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.limit(membersPageSize).get();
      if (snapshot.docs.isEmpty) break;

      for (final doc in snapshot.docs) {
        final member = ChurchMember.fromFirestore(doc);
        if (member.matchesSearchQuery(trimmedSearch)) {
          matches.add(member);
        }
      }

      cursor = snapshot.docs.last;
      if (snapshot.docs.length < membersPageSize) break;
    }

    matches.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

    return MembersPage(
      members: matches,
      hasMore: false,
      lastDocument: null,
    );
  }

  /// Exportación: recorre todas las páginas que coinciden con el filtro.
  Future<List<ChurchMember>> fetchAllMembersForExport({
    String? churchId,
    String? searchQuery,
    bool newBelieversOnly = false,
  }) async {
    final all = <ChurchMember>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      final page = await fetchMembersPage(
        churchId: churchId,
        searchQuery: searchQuery,
        startAfter: cursor,
        newBelieversOnly: newBelieversOnly,
        limit: membersPageSize,
      );
      all.addAll(page.members);
      if (!page.hasMore || page.lastDocument == null) break;
      cursor = page.lastDocument;
    }

    return all;
  }

  /// Totales de creyentes y asignados a líder (tarjeta resumen).
  Future<({int total, int assigned})> fetchMemberAssignmentStats({
    String? churchId,
  }) async {
    Query<Map<String, dynamic>> base = _members;
    if (churchId != null && churchId.isNotEmpty) {
      base = base.where('churchId', isEqualTo: churchId);
    }

    final totalFuture = base.count().get();
    final assignedFuture = base
        .where('assignedLeaderId', isGreaterThan: '')
        .count()
        .get();

    final results = await Future.wait([totalFuture, assignedFuture]);
    return (
      total: results[0].count ?? 0,
      assigned: results[1].count ?? 0,
    );
  }

  /// Solo integrantes asignados a un líder (lectura para rol líder).
  Stream<List<ChurchMember>> watchMembersAssignedToLeader({
    required String leaderId,
    String? churchId,
  }) {
    return _members
        .where('assignedLeaderId', isEqualTo: leaderId)
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs.map(ChurchMember.fromFirestore).toList();
      if (churchId != null && churchId.isNotEmpty) {
        list = list.where((member) {
          final memberChurchId = member.churchId?.trim();
          if (memberChurchId == null || memberChurchId.isEmpty) {
            return true;
          }
          return memberChurchId == churchId;
        }).toList();
      }
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  Future<String> addMember(
    ChurchMember member, {
    bool notifyLeader = true,
  }) async {
    final ref = await _members.add(member.toMap());
    if (notifyLeader) {
      await _notifyLeaderIfAssigned(
        memberId: ref.id,
        member: member,
        previousLeaderId: null,
      );
    }
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

  Stream<List<ChurchMember>> watchMembersInCell(String cellId) {
    return _members
        .where('assignedCellId', isEqualTo: cellId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(ChurchMember.fromFirestore).toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  Future<List<ChurchMember>> fetchMembersInCell(String cellId) async {
    if (cellId.isEmpty) return [];
    final snapshot =
        await _members.where('assignedCellId', isEqualTo: cellId).get();
    final list = snapshot.docs.map(ChurchMember.fromFirestore).toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  Future<List<ChurchMember>> fetchMembersWithoutCell({
    required String? churchId,
    LeaderGender? matchingGender,
  }) async {
    if (churchId == null || churchId.isEmpty) return [];

    final snapshot =
        await _members.where('churchId', isEqualTo: churchId).get();

    var list = snapshot.docs
        .map(ChurchMember.fromFirestore)
        .where((member) => !member.isAssignedToCell)
        .toList();
    if (matchingGender != null) {
      list = list.where((member) => member.gender == matchingGender).toList();
    }
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  Future<int> countMembersInCell(String cellId) async {
    if (cellId.isEmpty) return 0;
    final snapshot =
        await _members.where('assignedCellId', isEqualTo: cellId).get();
    return snapshot.docs.length;
  }

  Future<bool> assignMemberToCell({
    required ChurchMember member,
    required ChurchCell cell,
    String? actingLeaderId,
    LeaderGender? requiredLeaderGender,
    bool allowExceedCapacityForNewRegistration = false,
  }) async {
    final memberId = member.id;
    final cellId = cell.id;
    if (memberId == null || memberId.isEmpty) {
      throw ArgumentError('El integrante debe tener id');
    }
    if (cellId == null || cellId.isEmpty) {
      throw ArgumentError('La célula debe tener id');
    }

    if (requiredLeaderGender != null &&
        !memberMatchesCellLeaderGender(
          memberGender: member.gender,
          leaderGender: requiredLeaderGender,
        )) {
      throw CellAssignmentGenderException();
    }

    final currentCount = await countMembersInCell(cellId);
    if (allowExceedCapacityForNewRegistration &&
        currentCount >= CellMemberCapacity.maxMembers &&
        !CellMemberCapacity.isCellLeader(
          cell: cell,
          actingLeaderId: actingLeaderId,
        )) {
      throw CellAssignmentLeaderOnlyException();
    }
    if (!allowExceedCapacityForNewRegistration &&
        !CellMemberCapacity.canAssignAnother(
          currentCount: currentCount,
          cell: cell,
          actingLeaderId: actingLeaderId,
        )) {
      throw CellAssignmentLimitException();
    }

    final updates = <String, dynamic>{
      'assignedCellId': cellId,
      'assignedCellCode': cell.code.trim(),
      'assignmentKind': MemberAssignmentKind.cell.storageKey,
      'assignedLeaderFromRegistration': false,
    };

    await _members.doc(memberId).update(updates);

    final memberCount = await countMembersInCell(cellId);
    final capacityExceeded = memberCount > CellMemberCapacity.maxMembers;
    if (capacityExceeded) {
      _notifyCapacityExceededInBackground(
        cell: cell,
        memberCount: memberCount,
        memberId: memberId,
        memberName: member.fullName,
      );
    }
    return capacityExceeded;
  }

  void _notifyCapacityExceededInBackground({
    required ChurchCell cell,
    required int memberCount,
    required String memberId,
    required String memberName,
  }) {
    unawaited(
      _capacityNotificationService
          .notifyAdminsIfExceeded(
            cell: cell,
            memberCount: memberCount,
            memberId: memberId,
            memberName: memberName,
          )
          .catchError((_) => false),
    );
  }

  Future<void> unassignMemberFromCell(String memberId) async {
    if (memberId.isEmpty) {
      throw ArgumentError('El integrante debe tener id');
    }

    final memberRef = _members.doc(memberId);
    final memberSnap = await memberRef.get();
    if (!memberSnap.exists) return;

    final cellId =
        (memberSnap.data()?['assignedCellId'] as String? ?? '').trim();

    final batch = _members.firestore.batch();
    batch.update(memberRef, {
      'assignedCellId': FieldValue.delete(),
      'assignedCellCode': FieldValue.delete(),
    });

    if (cellId.isNotEmpty) {
      final cellRef = _members.firestore.collection('cells').doc(cellId);
      final cellSnap = await cellRef.get();
      if (cellSnap.exists) {
        final helpers =
            CellHelper.listFromFirestore(cellSnap.data()?['helpers']);
        if (helpers.any((helper) => helper.memberId == memberId)) {
          batch.update(cellRef, {
            'helpers': helpers
                .where((helper) => helper.memberId != memberId)
                .map((helper) => helper.toMap())
                .toList(),
          });
        }
      }
    }

    await batch.commit();
  }

  /// Tras registrar asistencia: quita `isNewBeliever` a quienes acumulan más de
  /// [cellPresentAttendancesToGraduateNewBeliever] presentes en la célula.
  Future<void> graduateNewBelieversFromCellAttendance({
    required String cellId,
  }) async {
    if (cellId.isEmpty) return;

    final sessionsSnapshot = await _members.firestore
        .collection('cells')
        .doc(cellId)
        .collection('sessions')
        .get();

    final presentCounts = <String, int>{};
    for (final doc in sessionsSnapshot.docs) {
      final records = CellAttendanceRecord.listFromFirestore(
        doc.data()['records'],
      );
      for (final record in records) {
        if (!record.present) continue;
        final id = record.memberId.trim();
        if (id.isEmpty) continue;
        presentCounts[id] = (presentCounts[id] ?? 0) + 1;
      }
    }

    final toGraduate = presentCounts.entries
        .where(
          (e) => e.value > cellPresentAttendancesToGraduateNewBeliever,
        )
        .map((e) => e.key)
        .toList();

    if (toGraduate.isEmpty) return;

    final batch = _members.firestore.batch();
    for (final memberId in toGraduate) {
      batch.update(_members.doc(memberId), {'isNewBeliever': false});
    }
    await batch.commit();
  }

  Future<void> _notifyLeaderIfAssigned({
    required String memberId,
    required ChurchMember member,
    required String? previousLeaderId,
  }) async {
    if (!member.isPastoralLeaderAssignment) return;
    final leaderId = member.assignedLeaderId?.trim();
    if (leaderId == null || leaderId.isEmpty) return;
    if (previousLeaderId != null && previousLeaderId == leaderId) return;

    try {
      await _notificationService.notifyMemberAssigned(
        leaderId: leaderId,
        memberId: memberId,
        memberName: member.fullName,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteMember(String id) {
    return _members.doc(id).delete();
  }

  static String messageForCellAssignmentLimit(AppLocalizations l10n) {
    return l10n.cellMemberAssignLimitReached;
  }

  static String messageForCellAssignmentGender(AppLocalizations l10n) {
    return l10n.cellMemberAssignGenderMismatch;
  }

  static String messageForCellAssignmentLeaderOnly(AppLocalizations l10n) {
    return l10n.cellMemberRegisterLeaderOnlyAtCapacity;
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
        return l10n.firestoreNotFound;
      case 'failed-precondition':
        return l10n.firestoreGenericError;
      default:
        return l10n.firestoreGenericError;
    }
  }
}
