import '../../auth/models/app_user_role.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/models/church_office.dart';
import '../../leaders/services/leader_service.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';
import '../cell_leader_gender.dart';
import '../models/cell_helper.dart';
import '../models/church_cell.dart';
import 'cell_service.dart';

class CellSplitService {
  CellSplitService({
    CellService? cellService,
    MemberService? memberService,
    LeaderService? leaderService,
    AuthService? authService,
    UserProfileService? userProfileService,
  })  : _cellService = cellService ?? CellService(),
        _memberService = memberService ?? MemberService(),
        _leaderService = leaderService ?? LeaderService(),
        _authService = authService ?? AuthService(),
        _userProfileService = userProfileService ?? UserProfileService();

  static const maxTransferMembers = 6;

  final CellService _cellService;
  final MemberService _memberService;
  final LeaderService _leaderService;
  final AuthService _authService;
  final UserProfileService _userProfileService;

  Future<ChurchLeader?> findExistingLeaderForMember({
    required ChurchMember member,
    required String churchId,
  }) async {
    final leaders =
        await _leaderService.fetchAssignableLeaders(churchId: churchId);
    final phone = _normalizePhone(member.phone);

    for (final leader in leaders) {
      if (leader.isBlocked) continue;
      if (_normalizePhone(leader.mobilePhone) == phone) return leader;
    }

    final nameKey = member.fullName.trim().toLowerCase();
    for (final leader in leaders) {
      if (leader.isBlocked) continue;
      if (leader.fullName.trim().toLowerCase() == nameKey) return leader;
    }

    return null;
  }

  bool leaderHasAppAccount(ChurchLeader leader) {
    final authUserId = leader.authUserId?.trim();
    return authUserId != null && authUserId.isNotEmpty;
  }

  Future<ChurchLeader> resolveLeaderForHelperMember({
    required ChurchMember member,
    required String churchId,
    required String registeredBy,
    String? email,
    String? password,
  }) async {
    final existing =
        await findExistingLeaderForMember(member: member, churchId: churchId);

    ChurchLeader leader;
    if (existing != null) {
      if (existing.isBlocked) {
        throw CellSplitLeaderBlockedException();
      }
      leader = await _ensureLeaderAppAccount(
        leader: existing,
        member: member,
        churchId: churchId,
        registeredBy: registeredBy,
        email: email,
        password: password,
      );
    } else {
      leader = await _createLeaderWithAppAccount(
        member: member,
        churchId: churchId,
        registeredBy: registeredBy,
        email: email,
        password: password,
      );
    }

    final memberId = member.id?.trim();
    final leaderId = leader.id?.trim();
    if (memberId != null &&
        memberId.isNotEmpty &&
        leaderId != null &&
        leaderId.isNotEmpty) {
      await _memberService.syncMemberForPromotedLeader(
        leader: leader,
        leaderId: leaderId,
        registeredBy: registeredBy,
        existingMemberId: memberId,
      );
    }

    return leader;
  }

  Future<ChurchLeader> _ensureLeaderAppAccount({
    required ChurchLeader leader,
    required ChurchMember member,
    required String churchId,
    required String registeredBy,
    String? email,
    String? password,
  }) async {
    if (leaderHasAppAccount(leader)) return leader;

    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPassword = password?.trim();
    if (normalizedEmail == null ||
        normalizedEmail.isEmpty ||
        normalizedPassword == null ||
        normalizedPassword.isEmpty) {
      throw CellSplitLeaderAccountRequiredException();
    }

    final credential = await _authService.createLeaderAccount(
      email: normalizedEmail,
      password: normalizedPassword,
    );
    final authUserId = credential.user?.uid;
    if (authUserId == null) {
      throw StateError('Could not create leader auth account');
    }

    final roles = AppUserRole.sanitizeForLeaderRegistration(
      leader.appRoles ?? const [AppUserRole.leader],
    );

    final updatedLeader = ChurchLeader(
      id: leader.id,
      lastName: leader.lastName,
      firstName: leader.firstName,
      street: leader.street,
      streetNumber: leader.streetNumber,
      cellCode: leader.cellCode,
      gender: leader.gender,
      idDocumentType: leader.idDocumentType,
      idDocumentNumber: leader.idDocumentNumber,
      birthDate: leader.birthDate,
      neighborhood: leader.neighborhood,
      locality: leader.locality,
      stateProvince: leader.stateProvince,
      postalCode: leader.postalCode,
      email: normalizedEmail,
      authUserId: authUserId,
      latitude: leader.latitude,
      longitude: leader.longitude,
      mobilePhone: leader.mobilePhone,
      registeredAt: leader.registeredAt,
      registeredBy: leader.registeredBy,
      churchId: leader.churchId ?? churchId,
      churchOffice: leader.churchOffice ?? ChurchOffice.lideres,
      appRoles: roles,
      isBlocked: leader.isBlocked,
    );

    await _leaderService.updateLeader(updatedLeader);
    await _userProfileService.setLeaderProfile(
      uid: authUserId,
      email: normalizedEmail,
      leaderId: leader.id!,
      roles: roles,
      churchId: churchId,
    );

    return updatedLeader;
  }

  Future<ChurchLeader> _createLeaderWithAppAccount({
    required ChurchMember member,
    required String churchId,
    required String registeredBy,
    String? email,
    String? password,
  }) async {
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPassword = password?.trim();
    if (normalizedEmail == null ||
        normalizedEmail.isEmpty ||
        normalizedPassword == null ||
        normalizedPassword.isEmpty) {
      throw CellSplitLeaderAccountRequiredException();
    }

    final credential = await _authService.createLeaderAccount(
      email: normalizedEmail,
      password: normalizedPassword,
    );
    final authUserId = credential.user?.uid;
    if (authUserId == null) {
      throw StateError('Could not create leader auth account');
    }

    final roles = AppUserRole.sanitizeForLeaderRegistration(
      const [AppUserRole.leader],
    );

    final leader = ChurchLeader(
      firstName: member.firstName,
      lastName: member.lastName,
      gender: member.gender,
      street: member.street,
      streetNumber: member.streetNumber,
      neighborhood: member.neighborhood,
      locality: member.locality,
      stateProvince: member.stateProvince,
      postalCode: member.postalCode,
      latitude: member.latitude,
      longitude: member.longitude,
      mobilePhone: member.phone,
      idDocumentType: member.idDocumentType,
      idDocumentNumber: member.idDocumentNumber,
      birthDate: member.birthDate,
      email: normalizedEmail,
      authUserId: authUserId,
      registeredAt: DateTime.now(),
      registeredBy: registeredBy,
      churchId: churchId,
      churchOffice: ChurchOffice.lideres,
      appRoles: roles,
    );

    final leaderId = await _leaderService.addLeader(leader);

    await _userProfileService.setLeaderProfile(
      uid: authUserId,
      email: normalizedEmail,
      leaderId: leaderId,
      roles: roles,
      churchId: churchId,
    );

    final created = await _leaderService.fetchLeaderById(leaderId);
    if (created == null) {
      throw StateError('Could not create leader for helper');
    }
    return created;
  }

  Future<ChurchCell> splitFromCapacity({
    required ChurchCell sourceCell,
    required ChurchCell newCell,
    required ChurchMember leaderHelperMember,
    required List<ChurchMember> membersToTransfer,
    required String registeredBy,
    String? leaderEmail,
    String? leaderPassword,
  }) async {
    final sourceCellId = sourceCell.id?.trim();
    final churchId = sourceCell.churchId?.trim();
    if (sourceCellId == null ||
        sourceCellId.isEmpty ||
        churchId == null ||
        churchId.isEmpty) {
      throw ArgumentError('Source cell and church are required');
    }

    if (membersToTransfer.length > maxTransferMembers) {
      throw ArgumentError('Too many members to transfer');
    }

    final leader = await resolveLeaderForHelperMember(
      member: leaderHelperMember,
      churchId: churchId,
      registeredBy: registeredBy,
      email: leaderEmail,
      password: leaderPassword,
    );

    final leaderId = leader.id?.trim();
    if (leaderId == null || leaderId.isEmpty) {
      throw StateError('Leader must have id');
    }

    final busyLeaderIds = await _cellService.fetchLeaderIdsWithAssignedCell(
      churchId: churchId,
    );
    if (busyLeaderIds.contains(leaderId)) {
      throw CellSplitLeaderBusyException();
    }

    final leaderGender = leader.gender;
    for (final member in membersToTransfer) {
      if (!memberMatchesCellLeaderGender(
        memberGender: member.gender,
        leaderGender: leaderGender,
      )) {
        throw CellSplitGenderMismatchException();
      }
    }

    final codeExists = await _cellService.codeExists(
      code: newCell.code,
      churchId: churchId,
    );
    if (codeExists) {
      throw CellSplitCodeDuplicateException();
    }

    final cellToCreate = ChurchCell(
      code: newCell.code,
      name: newCell.name,
      street: newCell.street,
      streetNumber: newCell.streetNumber,
      neighborhood: newCell.neighborhood,
      locality: newCell.locality,
      stateProvince: newCell.stateProvince,
      postalCode: newCell.postalCode,
      latitude: newCell.latitude,
      longitude: newCell.longitude,
      cellDay: newCell.cellDay,
      leaderId: leaderId,
      leaderName: leader.fullName,
      notes: newCell.notes,
      registeredAt: DateTime.now(),
      registeredBy: registeredBy,
      churchId: churchId,
    );

    final newCellId = await _cellService.addCell(cellToCreate);
    final createdCell = (await _cellService.fetchCellById(newCellId))!;

    final transferredIds = <String>{};
    for (final member in membersToTransfer) {
      final memberId = member.id?.trim();
      if (memberId == null || memberId.isEmpty) continue;
      await _memberService.assignMemberToCell(
        member: member,
        cell: createdCell,
        requiredLeaderGender: leaderGender,
        performedBy: registeredBy,
      );
      transferredIds.add(memberId);
    }

    final leaderMemberId = leaderHelperMember.id?.trim();
    if (leaderMemberId != null &&
        leaderMemberId.isNotEmpty &&
        !transferredIds.contains(leaderMemberId)) {
      await _memberService.unassignMemberFromCell(
        leaderMemberId,
        performedBy: registeredBy,
      );
    }

    final remainingHelpers = sourceCell.helpers
        .where(
          (helper) =>
              !transferredIds.contains(helper.memberId) &&
              helper.memberId != leaderMemberId,
        )
        .toList();
    await _cellService.updateCellHelpers(
      cellId: sourceCellId,
      helpers: remainingHelpers,
    );

    return createdCell;
  }

  List<ChurchMember> membersForHelpers({
    required List<CellHelper> helpers,
    required List<ChurchMember> cellMembers,
  }) {
    if (helpers.isEmpty) return const [];

    final byId = {
      for (final member in cellMembers)
        if (member.id != null && member.id!.trim().isNotEmpty)
          member.id!.trim(): member,
    };

    final result = <ChurchMember>[];
    for (final helper in helpers) {
      final member = byId[helper.memberId.trim()];
      if (member != null) result.add(member);
    }
    return result;
  }

  String _normalizePhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '');
}

class CellSplitLeaderBusyException implements Exception {}

class CellSplitGenderMismatchException implements Exception {}

class CellSplitCodeDuplicateException implements Exception {}

class CellSplitLeaderAccountRequiredException implements Exception {}

class CellSplitLeaderBlockedException implements Exception {}
