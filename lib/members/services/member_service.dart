import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cells/cell_leader_gender.dart';
import '../../cells/cell_member_capacity.dart';
import '../../cells/models/church_cell.dart';
import '../../core/models/leader_gender.dart';
import '../../l10n/app_localizations.dart';
import '../../notifications/services/cell_capacity_notification_service.dart';
import '../../notifications/services/leader_notification_service.dart';
import '../models/church_member.dart';

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
        list = list.where((m) => m.churchId == churchId).toList();
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
    await _members.doc(memberId).update({
      'assignedCellId': FieldValue.delete(),
      'assignedCellCode': FieldValue.delete(),
    });
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
      default:
        return l10n.firestoreGenericError;
    }
  }
}
