import 'package:cloud_firestore/cloud_firestore.dart';

import '../../leaders/models/church_leader.dart';
import '../../leaders/models/leader_registration_source.dart';
import '../../l10n/app_localizations.dart';
import '../models/leader_dashboard_data.dart';
import '../models/visit_chart_point.dart';
import 'visit_dashboard_service.dart';

class LeaderDashboardService {
  LeaderDashboardService({
    FirebaseFirestore? firestore,
    VisitDashboardService? visitDashboardService,
  })  : _leaders = (firestore ?? FirebaseFirestore.instance)
            .collection('leaders'),
        _visitDashboardService =
            visitDashboardService ?? VisitDashboardService();

  final CollectionReference<Map<String, dynamic>> _leaders;
  final VisitDashboardService _visitDashboardService;

  static const firstSelectableYear = 2015;

  static DateTime yearRangeStart(int year) => DateTime(year, 1, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

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

  Future<LeaderDashboardData> load({
    required String? churchId,
    required int selectedYear,
    int? selectedMonth,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final leaders = await _fetchLeaders(churchId);

    final rangeStart = yearRangeStart(selectedYear);
    final rangeEnd = yearRangeEnd(selectedYear, reference);

    final leadersInYear = leaders.where((leader) {
      final date = leader.registeredAt;
      return !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
    }).toList();

    final leadersInView = selectedMonth == null
        ? leadersInYear
        : leadersInYear
            .where(
              (leader) =>
                  leader.registeredAt.year == selectedYear &&
                  leader.registeredAt.month == selectedMonth,
            )
            .toList();

    leadersInView.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

    final fromCell = leadersInView
        .where(
          (leader) =>
              leader.registrationSource ==
              LeaderRegistrationSource.registerCell,
        )
        .length;

    final fromRegisterLeader = leadersInView
        .where(
          (leader) =>
              leader.registrationSource !=
              LeaderRegistrationSource.registerCell,
        )
        .length;

    return LeaderDashboardData(
      leaderChartPoints: _visitDashboardService.buildChartPointsFromDates(
        dates: leadersInYear.map((leader) => leader.registeredAt).toList(),
        period: VisitChartPeriod.month,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
      leadersCreatedInRange: leadersInView.length,
      leadersFromRegisterLeaderInRange: fromRegisterLeader,
      leadersFromCellInRange: fromCell,
      leadersInRange: leadersInView,
    );
  }

  Future<List<ChurchLeader>> _fetchLeaders(String? churchId) async {
    final normalizedChurchId = churchId?.trim();
    Query<Map<String, dynamic>> query = _leaders;
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: normalizedChurchId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(ChurchLeader.fromFirestore).toList();
  }

  static String messageFromException(Object error, AppLocalizations l10n) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return l10n.leaderDashboardDenied;
        case 'unavailable':
          return l10n.serviceUnavailable;
        default:
          return l10n.leaderDashboardLoadError;
      }
    }
    return l10n.leaderDashboardLoadError;
  }
}
