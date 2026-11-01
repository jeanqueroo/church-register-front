import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/user_profile.dart';
import '../../cells/models/church_cell.dart';
import '../../cells/services/cell_service.dart';
import '../../core/utils/birthday_date.dart';
import '../../core/utils/timed_cache.dart';
import '../../leaders/services/leader_service.dart';
import '../../members/models/church_member.dart';
import '../../supervisors/services/supervisor_assignment_service.dart';
import '../models/home_dashboard_data.dart';

class HomeDashboardService {
  HomeDashboardService({
    FirebaseFirestore? firestore,
    CellService? cellService,
    LeaderService? leaderService,
    SupervisorAssignmentService? supervisorAssignmentService,
    TimedCache<HomeDashboardData>? cache,
  })  : _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members'),
        _cells = (firestore ?? FirebaseFirestore.instance).collection('cells'),
        _baptismCalendar = (firestore ?? FirebaseFirestore.instance)
            .collection('baptismCalendar'),
        _cellService = cellService ?? CellService(),
        _leaderService = leaderService ?? LeaderService(),
        _supervisorAssignmentService =
            supervisorAssignmentService ?? SupervisorAssignmentService(),
        _cache = cache ?? _sharedCache;

  static final _sharedCache = TimedCache<HomeDashboardData>();

  final CollectionReference<Map<String, dynamic>> _members;
  final CollectionReference<Map<String, dynamic>> _cells;
  final CollectionReference<Map<String, dynamic>> _baptismCalendar;
  final CellService _cellService;
  final LeaderService _leaderService;
  final SupervisorAssignmentService _supervisorAssignmentService;
  final TimedCache<HomeDashboardData> _cache;

  static const _whereInLimit = 10;

  Future<HomeDashboardData> loadForSession(
    UserSession session, {
    bool forceRefresh = false,
  }) async {
    final churchId = session.profile.churchId?.trim();
    if (session.permissions.isAdmin &&
        churchId != null &&
        churchId.isNotEmpty) {
      return _loadForChurchAdmin(
        session: session,
        churchId: churchId,
        forceRefresh: forceRefresh,
      );
    }

    final resolved = await _resolveLeaderIds(session);
    final leaderIds = resolved.leaderIds;
    final cacheKey = _cacheKey(session, leaderIds);

    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) return cached;
    }

    final cells = await _cellService.fetchCellsForLeaderIds(
      leaderIds: leaderIds,
      churchId: churchId,
    );

    final birthdayCells = _cellsLedBy(
      leaderId: session.profile.leaderId?.trim(),
      from: cells,
    );
    final birthdayCellIds = birthdayCells
        .map((cell) => cell.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final birthdayCellCodeById = {
      for (final cell in birthdayCells)
        if (cell.id != null) cell.id!: cell.code,
    };

    final leaderBirthdaysFuture = _loadLeaderBirthdaysForCells(cells: birthdayCells);
    final birthdayMembersFuture = _loadBirthdaysForCells(
      cellIds: birthdayCellIds.toList(),
      cells: birthdayCells,
    );
    final discipleBirthdaysFuture = _loadDiscipleBirthdaysForCells(
      cellIds: birthdayCellIds.toList(),
      cellCodeById: birthdayCellCodeById,
    );

    final leaderBirthdays = await leaderBirthdaysFuture;
    final birthdayMembers = await birthdayMembersFuture;
    final discipleBirthdays = await discipleBirthdaysFuture;

    final seenBirthdays = <String>{};
    final birthdays = <CellBirthdayPerson>[];
    for (final person in [
      ...birthdayMembers,
      ...discipleBirthdays,
      ...leaderBirthdays,
    ]) {
      final key = '${person.name.trim().toLowerCase()}|${person.cellCode ?? ''}';
      if (seenBirthdays.add(key)) {
        birthdays.add(person);
      }
    }
    birthdays.sort((a, b) => a.name.compareTo(b.name));

    final ownCounts = await _loadOwnLeadershipCounts(
      session: session,
      cells: cells,
      churchId: churchId,
    );

    final data = HomeDashboardData(
      memberCount: ownCounts.memberCount,
      newBelieverCount: ownCounts.newBelieverCount,
      leaderCount: session.permissions.isSupervisor
          ? resolved.supervisedLeaderCount
          : null,
      birthdaysToday: birthdays,
      hasOwnCell: ownCounts.hasOwnCell,
    );

    _cache.set(cacheKey, data);
    return data;
  }

  Future<HomeDashboardData> _loadForChurchAdmin({
    required UserSession session,
    required String churchId,
    required bool forceRefresh,
  }) async {
    final cacheKey = 'admin:${session.uid}:$churchId';

    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) return cached;
    }

    final membersSnapshot =
        await _members.where('churchId', isEqualTo: churchId).get();
    final leaderCount =
        await _leaderService.countLeadersAndSupervisorsInChurch(
      churchId: churchId,
    );
    final cellsSnapshot =
        await _cells.where('churchId', isEqualTo: churchId).get();
    final baptismSnapshot =
        await _baptismCalendar.where('churchId', isEqualTo: churchId).get();

    var memberCount = 0;
    var newBelieverCount = 0;
   
    for (final doc in membersSnapshot.docs) {
      final member = ChurchMember.fromFirestore(doc);
      if (member.hasPromotedLeadershipStatus) {
        continue;
      }
      if (member.isNewBeliever) {
        newBelieverCount++;
        continue;
      }
       
      memberCount++;
    }

    var data = HomeDashboardData(
      memberCount: memberCount,
      newBelieverCount: newBelieverCount,
      leaderCount: leaderCount,
      cellCount: cellsSnapshot.docs.length,
      baptismCount: baptismSnapshot.docs.length,
    );

    if (session.permissions.isLeader || session.permissions.isSupervisor) {
      final own = await _loadPastoralOwnCountsForSession(session);
      data = HomeDashboardData(
        memberCount: data.memberCount,
        newBelieverCount: data.newBelieverCount,
        leaderCount: data.leaderCount,
        cellCount: data.cellCount,
        baptismCount: data.baptismCount,
        hasOwnCell: own.hasOwnCell,
        ownCellDiscipleCount: own.hasOwnCell ? own.memberCount : null,
      );
    }

    _cache.set(cacheKey, data);
    return data;
  }

  String _cacheKey(UserSession session, List<String> leaderIds) {
    final sortedIds = leaderIds.toList()..sort();
    return [
      session.uid,
      session.profile.churchId ?? '',
      sortedIds.join('|'),
    ].join(':');
  }

  List<ChurchCell> _cellsLedBy({
    required String? leaderId,
    required List<ChurchCell> from,
  }) {
    if (leaderId == null || leaderId.isEmpty) return [];
    return from.where((cell) => cell.leaderId?.trim() == leaderId).toList();
  }

  Future<List<CellBirthdayPerson>> _loadBirthdaysForCells({
    required List<String> cellIds,
    required List<ChurchCell> cells,
  }) async {
    if (cellIds.isEmpty) return [];

    final cellCodeById = {
      for (final cell in cells)
        if (cell.id != null) cell.id!: cell.code,
    };

    final birthdays = <CellBirthdayPerson>[];
    final countedMemberIds = <String>{};

    for (final cellId in cellIds) {
      final snapshot =
          await _members.where('assignedCellId', isEqualTo: cellId).get();

      for (final doc in snapshot.docs) {
        if (!countedMemberIds.add(doc.id)) continue;

        final member = ChurchMember.fromFirestore(doc);
        if (BirthdayDate.isToday(member.birthDate)) {
          birthdays.add(
            CellBirthdayPerson(
              name: member.fullName,
              age: member.age,
              cellCode: member.assignedCellCode ?? cellCodeById[cellId],
            ),
          );
        }
      }
    }

    for (final cell in cells) {
      final cellId = cell.id;
      if (cellId == null || cellId.isEmpty) continue;
      final cellCode = cell.code;

      for (final helper in cell.helpers) {
        final helperId = helper.memberId.trim();
        if (helperId.isEmpty || countedMemberIds.contains(helperId)) continue;

        final doc = await _members.doc(helperId).get();
        if (!doc.exists) continue;

        final member = ChurchMember.fromFirestore(doc);
        countedMemberIds.add(helperId);
        if (BirthdayDate.isToday(member.birthDate)) {
          birthdays.add(
            CellBirthdayPerson(
              name: member.fullName.isNotEmpty ? member.fullName : helper.fullName,
              age: member.age,
              cellCode: member.assignedCellCode ?? cellCode,
            ),
          );
        }
      }
    }

    return birthdays;
  }

  Future<({int count})> _loadMembersForCells({
    required List<String> cellIds,
    required List<ChurchCell> cells,
  }) async {
    if (cellIds.isEmpty) {
      return (count: 0);
    }

    var count = 0;
    final countedMemberIds = <String>{};

    for (final cellId in cellIds) {
      final snapshot =
          await _members.where('assignedCellId', isEqualTo: cellId).get();

      for (final doc in snapshot.docs) {
        if (!countedMemberIds.add(doc.id)) continue;

        count++;
      }
    }

    for (final cell in cells) {
      final cellId = cell.id;
      if (cellId == null || cellId.isEmpty) continue;

      for (final helper in cell.helpers) {
        final helperId = helper.memberId.trim();
        if (helperId.isEmpty || countedMemberIds.contains(helperId)) continue;

        final doc = await _members.doc(helperId).get();
        if (!doc.exists) continue;

        final member = ChurchMember.fromFirestore(doc);
        countedMemberIds.add(helperId);
        if (member.isNewBeliever) continue;
        count++;
      }
    }

    return (count: count);
  }

  Future<List<CellBirthdayPerson>> _loadLeaderBirthdaysForCells({
    required List<ChurchCell> cells,
  }) async {
    final birthdays = <CellBirthdayPerson>[];
    final seenLeaderIds = <String>{};

    for (final cell in cells) {
      final leaderId = cell.leaderId?.trim();
      if (leaderId == null || leaderId.isEmpty || !seenLeaderIds.add(leaderId)) {
        continue;
      }

      final leader = await _leaderService.fetchLeaderById(leaderId);
      if (leader == null || !BirthdayDate.isToday(leader.birthDate)) continue;

      birthdays.add(
        CellBirthdayPerson(
          name: leader.fullName,
          age: leader.age,
          cellCode: cell.code,
        ),
      );
    }

    return birthdays;
  }

  Future<int> _loadPastoralNewBelieversForLeaders({
    required List<String> leaderIds,
    required String? churchId,
  }) async {
    if (leaderIds.isEmpty ||
        churchId == null ||
        churchId.isEmpty) {
      return 0;
    }

    var count = 0;
    for (var i = 0; i < leaderIds.length; i += _whereInLimit) {
      final end = i + _whereInLimit > leaderIds.length
          ? leaderIds.length
          : i + _whereInLimit;
      final batch = leaderIds.sublist(i, end);

      final snapshot = await _members
          .where('churchId', isEqualTo: churchId)
          .where('assignedLeaderId', whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final member = ChurchMember.fromFirestore(doc);
        if (!member.isNewBeliever) continue;
        if (!member.isPastoralAssignmentFromRegisterMember) continue;
        count++;
      }
    }

    return count;
  }

  Future<List<CellBirthdayPerson>> _loadDiscipleBirthdaysForCells({
    required List<String> cellIds,
    required Map<String, String> cellCodeById,
  }) async {
    if (cellIds.isEmpty) return [];

    final snapshots = await Future.wait(
      cellIds.map(
        (cellId) => _cells.doc(cellId).collection('disciples').get(),
      ),
    );

    final birthdays = <CellBirthdayPerson>[];
    for (var index = 0; index < cellIds.length; index++) {
      final cellId = cellIds[index];
      final cellCode = cellCodeById[cellId];
      for (final doc in snapshots[index].docs) {
        final data = doc.data();
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final name = [firstName, lastName]
            .where((part) => part.trim().isNotEmpty)
            .join(' ')
            .trim();
        final birthDate = (data['birthDate'] as Timestamp?)?.toDate();
        if (BirthdayDate.isToday(birthDate)) {
          birthdays.add(
            CellBirthdayPerson(
              name: name.isEmpty ? 'Sin nombre' : name,
              age: _ageFromBirthDate(birthDate),
              cellCode: cellCode,
            ),
          );
        }
      }
    }

    return birthdays;
  }

  Future<({
    int memberCount,
    int newBelieverCount,
    bool hasOwnCell,
  })> _loadPastoralOwnCountsForSession(UserSession session) async {
    final churchId = session.profile.churchId?.trim();
    final ownLeaderId = session.profile.leaderId?.trim();
    if (ownLeaderId == null || ownLeaderId.isEmpty) {
      return (memberCount: 0, newBelieverCount: 0, hasOwnCell: false);
    }

    final cells = await _cellService.fetchCellsForLeaderIds(
      leaderIds: [ownLeaderId],
      churchId: churchId,
    );
    return _loadOwnLeadershipCounts(
      session: session,
      cells: cells,
      churchId: churchId,
    );
  }

  Future<({
    int memberCount,
    int newBelieverCount,
    bool hasOwnCell,
  })> _loadOwnLeadershipCounts({
    required UserSession session,
    required List<ChurchCell> cells,
    required String? churchId,
  }) async {
    final ownLeaderId = session.profile.leaderId?.trim();
    final ownCells = _cellsLedBy(leaderId: ownLeaderId, from: cells);
    final ownCellIds = ownCells
        .map((cell) => cell.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final ownCellMemberResult = await _loadMembersForCells(
      cellIds: ownCellIds,
      cells: ownCells,
    );
    final ownNewBelieverCount =
        ownLeaderId != null && ownLeaderId.isNotEmpty
            ? await _loadPastoralNewBelieversForLeaders(
                leaderIds: [ownLeaderId],
                churchId: churchId,
              )
            : 0;

    return (
      memberCount: ownCellMemberResult.count,
      newBelieverCount: ownNewBelieverCount,
      hasOwnCell: ownCells.isNotEmpty,
    );
  }

  Future<({List<String> leaderIds, int? supervisedLeaderCount})>
      _resolveLeaderIds(UserSession session) async {
    final leaderIds = <String>{};
    final permissions = session.permissions;
    List<String>? supervisedIds;

    if (permissions.isLeader || permissions.isSupervisor) {
      final ownLeaderId = session.profile.leaderId?.trim();
      if (ownLeaderId != null && ownLeaderId.isNotEmpty) {
        leaderIds.add(ownLeaderId);
      }
    }

    if (permissions.isSupervisor) {
      supervisedIds =
          await _supervisorAssignmentService.fetchSupervisedLeaderIds(
        session.uid,
      );
      leaderIds.addAll(supervisedIds);
    }

    return (
      leaderIds: leaderIds.toList(),
      supervisedLeaderCount:
          permissions.isSupervisor ? supervisedIds!.length : null,
    );
  }

  static int? _ageFromBirthDate(DateTime? birthDate) {
    final normalized = BirthdayDate.normalize(birthDate);
    if (normalized == null) return null;
    final now = DateTime.now();
    var years = now.year - normalized.year;
    if (now.month < normalized.month ||
        (now.month == normalized.month && now.day < normalized.day)) {
      years--;
    }
    return years;
  }
}
