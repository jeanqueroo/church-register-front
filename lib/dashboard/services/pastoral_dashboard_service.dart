import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/models/member_visit.dart';
import '../models/follow_up_person.dart';
import '../models/visit_chart_point.dart';
import '../models/visit_dashboard_filter.dart';
import 'visit_dashboard_service.dart';

class PrayerVisitStats {
  const PrayerVisitStats({
    required this.totalVisits,
    required this.prayerVisits,
  });

  final int totalVisits;
  final int prayerVisits;

  double get percentage =>
      totalVisits == 0 ? 0 : (prayerVisits / totalVisits) * 100;
}

class PastoralDashboardService {
  PastoralDashboardService({
    FirebaseFirestore? firestore,
    VisitDashboardService? visitDashboardService,
  })  : _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members'),
        _visitDashboardService =
            visitDashboardService ?? VisitDashboardService();

  final CollectionReference<Map<String, dynamic>> _members;
  final VisitDashboardService _visitDashboardService;

  Future<List<MemberVisit>> fetchVisits({
    required VisitDashboardFilter filter,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return _visitDashboardService.fetchVisits(
      filter: filter,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  Future<List<ChurchMember>> fetchNewMembers({
    required VisitDashboardFilter filter,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final leaderIds = filter.leaderIds;
    final List<ChurchMember> members;

    if (leaderIds != null) {
      if (leaderIds.isEmpty) return [];
      members = await _fetchMembersByLeaders(
        leaderIds: leaderIds,
        churchId: filter.churchId,
      );
    } else {
      members = await _fetchMembersMarkedAsNewBelievers(
        churchId: filter.churchId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }

    return members.where((member) {
      final at = member.effectiveNewBelieverAt;
      if (at == null) return false;
      return !at.isBefore(rangeStart) && !at.isAfter(rangeEnd);
    }).toList();
  }

  /// Incluye quienes tienen `newBelieverAt` en el rango y legacy con
  /// `isNewBeliever` + `registeredAt` (sin `newBelieverAt` aún).
  Future<List<ChurchMember>> _fetchMembersMarkedAsNewBelievers({
    String? churchId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    Query<Map<String, dynamic>> base = _members;
    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      base = base.where('churchId', isEqualTo: normalizedChurchId);
    }

    final byMarkedAt = await base
        .where(
          'newBelieverAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart),
        )
        .where(
          'newBelieverAt',
          isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd),
        )
        .get();

    final byLegacyFlag = await base
        .where('isNewBeliever', isEqualTo: true)
        .where(
          'registeredAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart),
        )
        .where(
          'registeredAt',
          isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd),
        )
        .get();

    final byId = <String, ChurchMember>{};
    for (final doc in byMarkedAt.docs) {
      byId[doc.id] = ChurchMember.fromFirestore(doc);
    }
    for (final doc in byLegacyFlag.docs) {
      final member = ChurchMember.fromFirestore(doc);
      if (member.newBelieverAt != null) continue;
      byId.putIfAbsent(doc.id, () => member);
    }
    return byId.values.toList();
  }

  Future<List<ChurchMember>> _fetchMembersByLeaders({
    required Set<String> leaderIds,
    String? churchId,
  }) async {
    final ids = leaderIds.toList()..sort();
    final members = <ChurchMember>[];
    const batchSize = 10;
    final batchFutures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];

    for (var i = 0; i < ids.length; i += batchSize) {
      final end = i + batchSize > ids.length ? ids.length : i + batchSize;
      final batch = ids.sublist(i, end);

      batchFutures.add(
        _members.where('assignedLeaderId', whereIn: batch).get(),
      );
    }

    final snapshots = await Future.wait(batchFutures);
    for (final snapshot in snapshots) {
      members.addAll(snapshot.docs.map(ChurchMember.fromFirestore));
    }

    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId == null || normalizedChurchId.isEmpty) {
      return members;
    }

    return members
        .where((member) => member.churchId == normalizedChurchId)
        .toList();
  }

  List<VisitChartPoint> buildNewMemberChartPoints({
    required List<ChurchMember> members,
    required VisitChartPeriod period,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return _visitDashboardService.buildChartPointsFromDates(
      dates: members
          .map((member) => member.effectiveNewBelieverAt)
          .whereType<DateTime>()
          .toList(),
      period: period,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  PrayerVisitStats prayerVisitStats(List<MemberVisit> visits) {
    final total = visits.length;
    final withPrayer = visits.where((visit) => visit.prayerPerformed).length;
    return PrayerVisitStats(totalVisits: total, prayerVisits: withPrayer);
  }

  List<FollowUpPerson> followUpPersonsFromVisits(List<MemberVisit> visits) {
    final latestByMember = <String, MemberVisit>{};

    for (final visit in visits) {
      if (!visit.needsFollowUp) continue;
      final memberId = visit.memberId.trim();
      if (memberId.isEmpty) continue;

      final existing = latestByMember[memberId];
      if (existing == null || visit.visitDate.isAfter(existing.visitDate)) {
        latestByMember[memberId] = visit;
      }
    }

    final people = latestByMember.entries
        .map(
          (entry) => FollowUpPerson(
            memberId: entry.key,
            memberName: entry.key,
            visitDate: entry.value.visitDate,
            leaderId: entry.value.leaderId,
          ),
        )
        .toList()
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

    return people;
  }

  Future<List<FollowUpPerson>> enrichFollowUpPersons(
    List<FollowUpPerson> people, {
    required Future<ChurchMember?> Function(String memberId) fetchMember,
    required Future<String?> Function(String leaderId) fetchLeaderName,
  }) async {
    if (people.isEmpty) return [];

    final memberIds = people.map((person) => person.memberId).toSet();
    final leaderIds = people
        .map((person) => person.leaderId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final memberEntries = await Future.wait(
      memberIds.map((memberId) async {
        final member = await fetchMember(memberId);
        return MapEntry(memberId, member?.fullName);
      }),
    );
    final leaderEntries = await Future.wait(
      leaderIds.map((leaderId) async {
        final leaderName = await fetchLeaderName(leaderId);
        return MapEntry(leaderId, leaderName);
      }),
    );

    final memberNames = Map<String, String?>.fromEntries(memberEntries);
    final leaderNames = Map<String, String?>.fromEntries(leaderEntries);

    return people
        .map(
          (person) => FollowUpPerson(
            memberId: person.memberId,
            memberName: memberNames[person.memberId] ?? person.memberId,
            visitDate: person.visitDate,
            leaderId: person.leaderId,
            leaderName: leaderNames[person.leaderId],
          ),
        )
        .toList();
  }

  Future<List<FollowUpPerson>> loadFollowUpPersons({
    required VisitDashboardFilter filter,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Future<ChurchMember?> Function(String memberId) fetchMember,
    required Future<String?> Function(String leaderId) fetchLeaderName,
  }) async {
    final visits = await fetchVisits(
      filter: filter,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    return loadFollowUpPersonsFromVisits(
      visits: visits,
      fetchMember: fetchMember,
      fetchLeaderName: fetchLeaderName,
    );
  }

  Future<List<FollowUpPerson>> loadFollowUpPersonsFromVisits({
    required List<MemberVisit> visits,
    required Future<ChurchMember?> Function(String memberId) fetchMember,
    required Future<String?> Function(String leaderId) fetchLeaderName,
  }) async {
    final people = followUpPersonsFromVisits(visits);
    return enrichFollowUpPersons(
      people,
      fetchMember: fetchMember,
      fetchLeaderName: fetchLeaderName,
    );
  }

  DateTime rangeStartFor(VisitChartPeriod period, DateTime now) =>
      _visitDashboardService.rangeStartFor(period, now);

  DateTime rangeStartForMonthCount(int monthCount, DateTime now) =>
      _visitDashboardService.rangeStartForMonthCount(monthCount, now);

  DateTime rangeEndFor(VisitChartPeriod period, DateTime now) =>
      _visitDashboardService.rangeEndFor(period, now);

  static String messageFromException(Object e, AppLocalizations l10n) =>
      VisitDashboardService.messageFromException(e, l10n);
}
