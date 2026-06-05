import 'package:cloud_firestore/cloud_firestore.dart';

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
      Query<Map<String, dynamic>> query = _members;
      final churchId = filter.churchId?.trim();
      if (churchId != null && churchId.isNotEmpty) {
        query = query.where('churchId', isEqualTo: churchId);
      }
      final snapshot = await query.get();
      members = snapshot.docs.map(ChurchMember.fromFirestore).toList();
    }

    return members.where((member) {
      final registeredAt = member.registeredAt;
      return !registeredAt.isBefore(rangeStart) &&
          !registeredAt.isAfter(rangeEnd);
    }).toList();
  }

  Future<List<ChurchMember>> _fetchMembersByLeaders({
    required Set<String> leaderIds,
    String? churchId,
  }) async {
    final ids = leaderIds.toList()..sort();
    final members = <ChurchMember>[];
    const batchSize = 10;

    for (var i = 0; i < ids.length; i += batchSize) {
      final end = i + batchSize > ids.length ? ids.length : i + batchSize;
      final batch = ids.sublist(i, end);

      final snapshot = await _members
          .where('assignedLeaderId', whereIn: batch)
          .get();
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
      dates: members.map((member) => member.registeredAt).toList(),
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
    final enriched = <FollowUpPerson>[];
    for (final person in people) {
      final member = await fetchMember(person.memberId);
      final leaderName = await fetchLeaderName(person.leaderId);
      enriched.add(
        FollowUpPerson(
          memberId: person.memberId,
          memberName: member?.fullName ?? person.memberId,
          visitDate: person.visitDate,
          leaderId: person.leaderId,
          leaderName: leaderName,
        ),
      );
    }
    return enriched;
  }

  DateTime rangeStartFor(VisitChartPeriod period, DateTime now) =>
      _visitDashboardService.rangeStartFor(period, now);

  DateTime rangeEndFor(VisitChartPeriod period, DateTime now) =>
      _visitDashboardService.rangeEndFor(period, now);

  static String messageFromException(Object e) =>
      VisitDashboardService.messageFromException(e);
}
