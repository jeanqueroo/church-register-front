import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/user_profile.dart';
import '../../cells/services/cell_service.dart';
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
        _cellService = cellService ?? CellService(),
        _leaderService = leaderService ?? LeaderService(),
        _supervisorAssignmentService =
            supervisorAssignmentService ?? SupervisorAssignmentService(),
        _cache = cache ?? _sharedCache;

  static final _sharedCache = TimedCache<HomeDashboardData>();

  final CollectionReference<Map<String, dynamic>> _members;
  final CollectionReference<Map<String, dynamic>> _cells;
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

    final cellIds = cells
        .map((cell) => cell.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final cellIdSet = cellIds.toSet();
    final cellCodeById = {
      for (final cell in cells)
        if (cell.id != null) cell.id!: cell.code,
    };

    final memberResultsFuture = _loadMembersForCells(
      cellIds: cellIds,
      cellIdSet: cellIdSet,
      churchId: churchId,
    );
    final discipleResultsFuture = _loadDisciplesForCells(
      cellIds: cellIds,
      cellCodeById: cellCodeById,
    );

    final memberResult = await memberResultsFuture;
    final discipleResult = await discipleResultsFuture;
    final assignedNewBelieverCount = await _loadPastoralNewBelieversForLeaders(
      leaderIds: leaderIds,
      churchId: churchId,
    );

    final birthdays = [
      ...memberResult.birthdays,
      ...discipleResult.birthdays,
    ]..sort((a, b) => a.name.compareTo(b.name));

    final data = HomeDashboardData(
      memberCount: memberResult.count,
      newBelieverCount: assignedNewBelieverCount,
      leaderCount: resolved.supervisedLeaderCount,
      birthdaysToday: birthdays,
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

    var memberCount = 0;
    var newBelieverCount = 0;
    for (final doc in membersSnapshot.docs) {
      final member = ChurchMember.fromFirestore(doc);
      if (member.hasPromotedLeadershipStatus) {
        continue;
      }
      memberCount++;
      if (member.isNewBeliever) {
        newBelieverCount++;
      }
    }

    final data = HomeDashboardData(
      memberCount: memberCount,
      newBelieverCount: newBelieverCount,
      leaderCount: leaderCount,
    );

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

  Future<({int count, List<CellBirthdayPerson> birthdays})> _loadMembersForCells({
    required List<String> cellIds,
    required Set<String> cellIdSet,
    required String? churchId,
  }) async {
    if (cellIds.isEmpty ||
        churchId == null ||
        churchId.isEmpty ||
        cellIdSet.isEmpty) {
      return (count: 0, birthdays: <CellBirthdayPerson>[]);
    }

    var count = 0;
    final birthdays = <CellBirthdayPerson>[];

    for (var i = 0; i < cellIds.length; i += _whereInLimit) {
      final end = i + _whereInLimit > cellIds.length
          ? cellIds.length
          : i + _whereInLimit;
      final batch = cellIds.sublist(i, end);

      final snapshot = await _members
          .where('churchId', isEqualTo: churchId)
          .where('assignedCellId', whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final member = ChurchMember.fromFirestore(doc);
        count++;
        if (_isBirthdayToday(member.birthDate)) {
          birthdays.add(
            CellBirthdayPerson(
              name: member.fullName,
              age: member.age,
              cellCode: member.assignedCellCode,
            ),
          );
        }
      }
    }

    return (count: count, birthdays: birthdays);
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
        if (doc.data()['isNewBeliever'] == true) {
          count++;
        }
      }
    }

    return count;
  }

  Future<({int count, List<CellBirthdayPerson> birthdays})> _loadDisciplesForCells({
    required List<String> cellIds,
    required Map<String, String> cellCodeById,
  }) async {
    if (cellIds.isEmpty) {
      return (count: 0, birthdays: <CellBirthdayPerson>[]);
    }

    final snapshots = await Future.wait(
      cellIds.map(
        (cellId) => _cells.doc(cellId).collection('disciples').get(),
      ),
    );

    var count = 0;
    final birthdays = <CellBirthdayPerson>[];
    for (var index = 0; index < cellIds.length; index++) {
      final cellId = cellIds[index];
      final cellCode = cellCodeById[cellId];
      for (final doc in snapshots[index].docs) {
        count++;
        final data = doc.data();
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final name = [firstName, lastName]
            .where((part) => part.trim().isNotEmpty)
            .join(' ')
            .trim();
        final birthDate = (data['birthDate'] as Timestamp?)?.toDate();
        if (_isBirthdayToday(birthDate)) {
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

    return (count: count, birthdays: birthdays);
  }

  Future<({List<String> leaderIds, int? supervisedLeaderCount})>
      _resolveLeaderIds(UserSession session) async {
    final leaderIds = <String>{};
    final permissions = session.permissions;
    List<String>? supervisedIds;

    if (permissions.isLeader) {
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

  static bool _isBirthdayToday(DateTime? birthDate) {
    if (birthDate == null) return false;
    final now = DateTime.now();
    return birthDate.month == now.month && birthDate.day == now.day;
  }

  static int? _ageFromBirthDate(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }
}
