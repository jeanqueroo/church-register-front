import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/models/member_registration_source.dart';
import '../models/baptism_dashboard_data.dart';
import '../models/visit_chart_point.dart';
import 'visit_dashboard_service.dart';

class BaptismDashboardService {
  BaptismDashboardService({
    FirebaseFirestore? firestore,
    VisitDashboardService? visitDashboardService,
  })  : _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members'),
        _visitDashboardService =
            visitDashboardService ?? VisitDashboardService();

  final CollectionReference<Map<String, dynamic>> _members;
  final VisitDashboardService _visitDashboardService;

  static const firstSelectableYear = 2015;

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  static DateTime yearRangeStart(int year) => DateTime(year, 1, 1);

  static DateTime yearRangeEnd(int year, DateTime now) {
    if (year < now.year) {
      return DateTime(year, 12, 31, 23, 59, 59, 999);
    }
    if (year == now.year) {
      return endOfMonth(DateTime(now.year, now.month, 1));
    }
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }

  static int lastSelectableMonth(int year, DateTime now) {
    if (year < now.year) return 12;
    if (year == now.year) return now.month;
    return 12;
  }

  Future<BaptismDashboardData> load({
    required String? churchId,
    required int selectedYear,
    int? selectedMonth,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final baptizedMembers = await _fetchBaptized(churchId);

    final rangeStart = yearRangeStart(selectedYear);
    final rangeEnd = yearRangeEnd(selectedYear, reference);

    final baptizedInYear = baptizedMembers.where((member) {
      final date = member.baptizedAt!;
      return !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
    }).toList();

    final baptizedInView = selectedMonth == null
        ? baptizedInYear
        : baptizedInYear
            .where(
              (member) =>
                  member.baptizedAt!.year == selectedYear &&
                  member.baptizedAt!.month == selectedMonth,
            )
            .toList();

    baptizedInView.sort((a, b) => b.baptizedAt!.compareTo(a.baptizedAt!));

    final newBelieversBaptizedInRange = baptizedInView
        .where(
          (member) =>
              member.registrationSource ==
              MemberRegistrationSource.registerMember,
        )
        .length;

    return BaptismDashboardData(
      baptismChartPoints: _visitDashboardService.buildChartPointsFromDates(
        dates: baptizedInYear.map((member) => member.baptizedAt!).toList(),
        period: VisitChartPeriod.month,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
      baptizedInRange: baptizedInView.length,
      newBelieversBaptizedInRange: newBelieversBaptizedInRange,
      baptizedMembersInRange: baptizedInView,
    );
  }

  Future<List<ChurchMember>> _fetchBaptized(String? churchId) async {
    final normalizedChurchId = churchId?.trim();
    Query<Map<String, dynamic>> query =
        _members.where('isBaptized', isEqualTo: true);
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: normalizedChurchId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map(ChurchMember.fromFirestore)
        .where((member) => member.baptizedAt != null)
        .toList();
  }

  static String messageFromException(Object error, AppLocalizations l10n) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return l10n.baptismDashboardDenied;
        case 'unavailable':
          return l10n.serviceUnavailable;
        default:
          return l10n.baptismDashboardLoadError;
      }
    }
    return l10n.baptismDashboardLoadError;
  }
}
