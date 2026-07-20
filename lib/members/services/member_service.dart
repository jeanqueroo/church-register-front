import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cells/cell_leader_gender.dart';
import '../../cells/cell_member_capacity.dart';
import '../../cells/models/church_cell.dart';
import '../../core/models/leader_gender.dart';
import '../../core/search/firestore_search_text.dart';
import '../../auth/models/app_user_role.dart';
import '../../l10n/app_localizations.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/models/church_office.dart';
import '../../notifications/services/cell_capacity_notification_service.dart';
import '../../notifications/services/leader_notification_service.dart';
import '../models/church_member.dart';
import '../models/member_assignment_kind.dart';
import '../models/member_history_event.dart';
import '../models/member_leadership_status.dart';
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

  CollectionReference<Map<String, dynamic>> get _cells =>
      _members.firestore.collection('cells');

  Future<void> _adjustCellMemberCount(String cellId, int delta) async {
    if (cellId.trim().isEmpty || delta == 0) return;
    await _cells.doc(cellId).set(
      {'memberCount': FieldValue.increment(delta)},
      SetOptions(merge: true),
    );
  }

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
    bool newBelieversOnly = false,
  }) async {
    Query<Map<String, dynamic>> base = _members;
    if (churchId != null && churchId.isNotEmpty) {
      base = base.where('churchId', isEqualTo: churchId);
    }
    if (newBelieversOnly) {
      base = base.where('isNewBeliever', isEqualTo: true);
    }

    final totalFuture = base.count().get();
    Query<Map<String, dynamic>> assignedQuery = base;
    assignedQuery = assignedQuery.where('assignedLeaderId', isGreaterThan: '');
    final assignedFuture = assignedQuery.count().get();

    final results = await Future.wait([totalFuture, assignedFuture]);
    return (
      total: results[0].count ?? 0,
      assigned: results[1].count ?? 0,
    );
  }

  /// Solo nuevos creyentes asignados a un líder (lectura para rol líder).
  Stream<List<ChurchMember>> watchMembersAssignedToLeader({
    required String leaderId,
    String? churchId,
  }) {
    return _members
        .where('assignedLeaderId', isEqualTo: leaderId)
        .where('isNewBeliever', isEqualTo: true)
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
      list = list
          .where((member) => member.isPastoralAssignmentFromRegisterMember)
          .toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  Future<String> addMember(
    ChurchMember member, {
    bool notifyLeader = true,
  }) async {
    final ref = await _members.add(member.toMap());
    await _appendMemberHistory(
      memberId: ref.id,
      event: MemberHistoryEvent(
        type: MemberHistoryEventType.registered,
        occurredAt: member.registeredAt,
        performedBy: member.registeredBy,
        details: {
          if (member.registrationSource != null)
            'registrationSource': member.registrationSource!.storageKey,
          if (member.churchId != null) 'churchId': member.churchId,
        },
      ),
    );
    if (member.pastoralAssignedAt != null &&
        member.assignedLeaderId?.trim().isNotEmpty == true) {
      await _appendMemberHistory(
        memberId: ref.id,
        event: MemberHistoryEvent(
          type: MemberHistoryEventType.pastoralAssigned,
          occurredAt: member.pastoralAssignedAt!,
          performedBy: member.registeredBy,
          details: {
            'leaderId': member.assignedLeaderId,
            if (member.assignedLeaderName != null)
              'leaderName': member.assignedLeaderName,
          },
        ),
      );
    }
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
    final data = member.toMap();
    if (!member.isBaptized) {
      data['baptizedAt'] = FieldValue.delete();
    }
    await _members.doc(id).update(data);
    await _notifyLeaderIfAssigned(
      memberId: id,
      member: member,
      previousLeaderId: previousAssignedLeaderId,
    );
  }

  Future<void> updateMembersBaptismConfirmation({
    required List<String> baptizedMemberIds,
    required List<String> notBaptizedMemberIds,
    required DateTime baptizedAt,
    String? performedBy,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final at = Timestamp.fromDate(
      DateTime(baptizedAt.year, baptizedAt.month, baptizedAt.day),
    );
    final confirmedAt = DateTime.now();

    for (final id in baptizedMemberIds) {
      if (id.trim().isEmpty) continue;
      batch.update(_members.doc(id), {
        'isBaptized': true,
        'isNewBeliever': false,
        'baptizedAt': at,
      });
    }

    for (final id in notBaptizedMemberIds) {
      if (id.trim().isEmpty) continue;
      batch.update(_members.doc(id), {
        'isBaptized': false,
        'baptizedAt': FieldValue.delete(),
      });
    }

    if (baptizedMemberIds.isEmpty && notBaptizedMemberIds.isEmpty) return;
    await batch.commit();

    for (final id in baptizedMemberIds) {
      if (id.trim().isEmpty) continue;
      await _appendMemberHistory(
        memberId: id,
        event: MemberHistoryEvent(
          type: MemberHistoryEventType.baptizedConfirmed,
          occurredAt: confirmedAt,
          performedBy: performedBy,
          details: {
            'baptizedAt': at.millisecondsSinceEpoch,
          },
        ),
      );
    }
  }

  Future<void> markMemberPromotedToLeader({
    required String memberId,
    required String leaderId,
  }) {
    return markMemberLeadershipStatus(
      memberId: memberId,
      leaderId: leaderId,
      status: MemberLeadershipStatus.promotedToLeader,
    );
  }

  Future<void> markMemberLeadershipStatus({
    required String memberId,
    required String leaderId,
    required MemberLeadershipStatus status,
  }) async {
    if (memberId.isEmpty || leaderId.isEmpty) {
      throw ArgumentError('memberId and leaderId are required');
    }
    await _members.doc(memberId).update({
      'leadershipStatus': status.name,
      'linkedLeaderId': leaderId,
      'promotedToLeaderAt': FieldValue.serverTimestamp(),
      'isNewBeliever': false,
    });
  }

  static MemberLeadershipStatus leadershipStatusForLeader(ChurchLeader leader) {
    final roles = leader.appRoles ?? const <String>[];
    if (roles.contains(AppUserRole.registrar) ||
        leader.churchOffice == ChurchOffice.voluntario) {
      return MemberLeadershipStatus.promotedToVolunteer;
    }
    return MemberLeadershipStatus.promotedToLeader;
  }

  /// Registro directo en «Nuevo líder» (rol líder o supervisor).
  static MemberLeadershipStatus leadershipStatusForNewLeaderRegistration(
    ChurchLeader leader,
  ) {
    final roles = leader.appRoles ?? const <String>[];
    if (roles.contains(AppUserRole.registrar) ||
        leader.churchOffice == ChurchOffice.voluntario) {
      return MemberLeadershipStatus.promotedToVolunteer;
    }
    return MemberLeadershipStatus.createdAsLeader;
  }

  /// Crea un integrante vinculado a un líder recién registrado.
  Future<String> createMemberForLeader({
    required ChurchLeader leader,
    required String leaderId,
    required String registeredBy,
  }) async {
    final now = DateTime.now();
    final leadershipStatus = leadershipStatusForNewLeaderRegistration(leader);
    final member = ChurchMember(
      firstName: leader.firstName,
      lastName: leader.lastName,
      gender: leader.gender,
      street: leader.street,
      streetNumber: leader.streetNumber,
      neighborhood: leader.neighborhood,
      locality: leader.locality,
      stateProvince: leader.stateProvince,
      postalCode: leader.postalCode,
      latitude: leader.latitude,
      longitude: leader.longitude,
      phone: leader.mobilePhone,
      idDocumentType: leader.idDocumentType,
      idDocumentNumber: leader.idDocumentNumber,
      birthDate: leader.birthDate,
      isNewBeliever: false,
      isBaptized: true,
      baptizedAt: now,
      wantsVisit: false,
      formDate: now,
      registeredAt: leader.registeredAt,
      registeredBy: registeredBy,
      churchId: leader.churchId,
      leadershipStatus: leadershipStatus,
      linkedLeaderId: leaderId,
      promotedToLeaderAt: now,
    );
    return addMember(member, notifyLeader: false);
  }

  /// Si ya existe integrante (p. ej. ayudante de célula), lo marca; si no, crea uno.
  Future<void> syncMemberForPromotedLeader({
    required ChurchLeader leader,
    required String leaderId,
    required String registeredBy,
    String? existingMemberId,
  }) async {
    final memberId = existingMemberId?.trim();
    if (memberId != null && memberId.isNotEmpty) {
      await markMemberLeadershipStatus(
        memberId: memberId,
        leaderId: leaderId,
        status: MemberLeadershipStatus.promotedToLeader,
      );
      return;
    }
    await createMemberForLeader(
      leader: leader,
      leaderId: leaderId,
      registeredBy: registeredBy,
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

  /// Integrantes sin bautizar disponibles para asignar a una fecha de bautismo.
  Future<List<ChurchMember>> fetchMembersForBaptismAssignment({
    required String? churchId,
    String? assignedLeaderId,
    Set<String> includeMemberIds = const {},
  }) async {
    if (churchId == null || churchId.isEmpty) return [];

    Query<Map<String, dynamic>> query =
        _members.where('churchId', isEqualTo: churchId);
    final leaderId = assignedLeaderId?.trim();
    if (leaderId != null && leaderId.isNotEmpty) {
      query = query.where('assignedLeaderId', isEqualTo: leaderId);
    }

    final snapshot = await query.get();
    final pastBaptizedIds = await _memberIdsFromPastBaptisms(churchId);
    final list = snapshot.docs.map(ChurchMember.fromFirestore).where((member) {
      final id = member.id;
      if (id == null || id.isEmpty) return false;
      if (includeMemberIds.contains(id)) return true;
      if (!member.canBeAssignedToBaptism) return false;
      if (pastBaptizedIds.contains(id)) return false;
      return true;
    }).toList();
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  Future<Set<String>> _memberIdsFromPastBaptisms(String churchId) async {
    final snapshot = await (FirebaseFirestore.instance)
        .collection('baptismCalendar')
        .where('churchId', isEqualTo: churchId)
        .get();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final ids = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final baptismTimestamp = data['baptismDate'];
      if (baptismTimestamp is! Timestamp) continue;
      final baptismDate = baptismTimestamp.toDate();
      final dateOnly = DateTime(
        baptismDate.year,
        baptismDate.month,
        baptismDate.day,
      );
      if (dateOnly.isAfter(todayOnly)) continue;

      final assigned = data['assignedMembers'];
      if (assigned is! List) continue;
      for (final item in assigned) {
        if (item is! Map) continue;
        final memberId = item['memberId'];
        if (memberId is String && memberId.isNotEmpty) {
          ids.add(memberId);
        }
      }
    }

    return ids;
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
        .where((member) => member.canBeAssignedAsCellDisciple)
        .toList();
    if (matchingGender != null) {
      list = list.where((member) => member.gender == matchingGender).toList();
    }
    list.sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  }

  /// Discípulos del líder de la célula (registro pastoral) aún sin célula asignada.
  Future<List<ChurchMember>> fetchMembersForCellAssignment({
    required String? churchId,
    required String? cellLeaderId,
    LeaderGender? matchingGender,
  }) async {
    if (churchId == null || churchId.isEmpty) return [];

    final leaderId = cellLeaderId?.trim();
    if (leaderId == null || leaderId.isEmpty) return [];

    final snapshot = await _members
        .where('churchId', isEqualTo: churchId)
        .where('assignedLeaderId', isEqualTo: leaderId)
        .get();

    var list = snapshot.docs
        .map(ChurchMember.fromFirestore)
        .where((member) => !member.isAssignedToCell)
        .where((member) => member.canBeAssignedAsCellDisciple)
        .where((member) => member.isPastoralAssignmentFromRegisterMember)
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

  /// Integrantes asignados por `assignedCellId` (una consulta por iglesia).
  Future<Map<String, int>> fetchMemberCountsByCellForChurch(
    String? churchId,
  ) async {
    Query<Map<String, dynamic>> query = _members;
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }

    final snapshot = await query.get();
    final counts = <String, int>{};

    for (final doc in snapshot.docs) {
      final cellId = (doc.data()['assignedCellId'] as String? ?? '').trim();
      if (cellId.isEmpty) continue;
      counts[cellId] = (counts[cellId] ?? 0) + 1;
    }

    return counts;
  }

  Future<bool> assignMemberToCell({
    required ChurchMember member,
    required ChurchCell cell,
    String? actingLeaderId,
    LeaderGender? requiredLeaderGender,
    bool allowExceedCapacityForNewRegistration = false,
    String? performedBy,
    Iterable<String> supervisedLeaderIds = const [],
  }) async {
    final memberId = member.id;
    final cellId = cell.id;
    if (memberId == null || memberId.isEmpty) {
      throw ArgumentError('El integrante debe tener id');
    }
    if (cellId == null || cellId.isEmpty) {
      throw ArgumentError('La célula debe tener id');
    }

    if (!member.canBeAssignedAsCellDisciple) {
      throw CellAssignmentLeaderException();
    }

    if (requiredLeaderGender != null &&
        !memberMatchesCellLeaderGender(
          memberGender: member.gender,
          leaderGender: requiredLeaderGender,
        )) {
      throw CellAssignmentGenderException();
    }

    final currentCount = cell.memberCount ?? await countMembersInCell(cellId);
    if (currentCount >= CellMemberCapacity.maxAssignableMembers) {
      throw CellAssignmentLimitException();
    }
    if (allowExceedCapacityForNewRegistration &&
        currentCount >= CellMemberCapacity.maxMembers &&
        !CellMemberCapacity.canManageCellMembers(
          cell: cell,
          actingLeaderId: actingLeaderId,
          supervisedLeaderIds: supervisedLeaderIds,
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

    final memberSnap = await _members.doc(memberId).get();
    final existingData = memberSnap.data();
    final previousCellId =
        (existingData?['assignedCellId'] as String? ?? '').trim();
    final hasCellAssignedAt =
        existingData?['cellAssignedAt'] is Timestamp;

    final updates = <String, dynamic>{
      'assignedCellId': cellId,
      'assignedCellCode': cell.code.trim(),
      'assignmentKind': MemberAssignmentKind.cell.storageKey,
      'assignedLeaderFromRegistration': false,
      if (!hasCellAssignedAt) 'cellAssignedAt': FieldValue.serverTimestamp(),
    };

    await _members.doc(memberId).update(updates);

    if (previousCellId != cellId) {
      if (previousCellId.isNotEmpty) {
        await _adjustCellMemberCount(previousCellId, -1);
      }
      await _adjustCellMemberCount(cellId, 1);
    }

    await _appendMemberHistory(
      memberId: memberId,
      event: MemberHistoryEvent(
        type: MemberHistoryEventType.cellAssigned,
        occurredAt: DateTime.now(),
        performedBy: performedBy ?? member.registeredBy,
        details: {
          'cellId': cellId,
          'cellCode': cell.code.trim(),
          if (actingLeaderId != null) 'actingLeaderId': actingLeaderId,
        },
      ),
    );

    final memberCount =
        previousCellId == cellId ? currentCount : currentCount + 1;
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

  Future<void> unassignMemberFromCell(
    String memberId, {
    String? performedBy,
  }) async {
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

    if (cellId.isNotEmpty) {
      await _adjustCellMemberCount(cellId, -1);
      await _appendMemberHistory(
        memberId: memberId,
        event: MemberHistoryEvent(
          type: MemberHistoryEventType.cellUnassigned,
          occurredAt: DateTime.now(),
          performedBy: performedBy,
          details: {'cellId': cellId},
        ),
      );
    }
  }

  CollectionReference<Map<String, dynamic>> _memberHistory(String memberId) {
    return _members.doc(memberId).collection('history');
  }

  Future<void> _appendMemberHistory({
    required String memberId,
    required MemberHistoryEvent event,
  }) async {
    if (memberId.trim().isEmpty) return;
    await _memberHistory(memberId).add(event.toMap());
  }

  Stream<List<MemberHistoryEvent>> watchMemberHistory(String memberId) {
    return _memberHistory(memberId)
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MemberHistoryEvent.fromFirestore)
              .toList(),
        );
  }

  /// Al asignar ayudantes de célula dejan de figurar como nuevo creyente.
  Future<void> clearNewBelieverForCellHelpers(Iterable<String> memberIds) async {
    final ids = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return;

    final batch = _members.firestore.batch();
    for (final memberId in ids) {
      batch.update(_members.doc(memberId), {'isNewBeliever': false});
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
    return l10n.cellMemberAssignLimitReached(
      CellMemberCapacity.maxAssignableMembers,
    );
  }

  static String messageForCellAssignmentGender(AppLocalizations l10n) {
    return l10n.cellMemberAssignGenderMismatch;
  }

  static String messageForCellAssignmentLeaderOnly(AppLocalizations l10n) {
    return l10n.cellMemberRegisterLeaderOnlyAtCapacity;
  }

  static String messageForCellAssignmentLeader(AppLocalizations l10n) {
    return l10n.cellMemberAssignLeaderExcluded;
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
