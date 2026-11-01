import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cells/models/church_cell.dart';
import '../../l10n/app_localizations.dart';
import '../models/cell_dashboard_data.dart';
import '../models/visit_chart_point.dart';
import 'visit_dashboard_service.dart';

class CellDashboardService {
  CellDashboardService({
    FirebaseFirestore? firestore,
    VisitDashboardService? visitDashboardService,
  })  : _cells = (firestore ?? FirebaseFirestore.instance).collection('cells'),
        _visitDashboardService =
            visitDashboardService ?? VisitDashboardService();

  final CollectionReference<Map<String, dynamic>> _cells;
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

  Future<CellDashboardData> load({
    required String? churchId,
    required int selectedYear,
    int? selectedMonth,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final cells = await _fetchCells(churchId);

    final rangeStart = yearRangeStart(selectedYear);
    final rangeEnd = yearRangeEnd(selectedYear, reference);

    final cellsInYear = cells.where((cell) {
      final date = cell.registeredAt;
      return !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
    }).toList();

    final cellsInView = selectedMonth == null
        ? cellsInYear
        : cellsInYear
            .where(
              (cell) =>
                  cell.registeredAt.year == selectedYear &&
                  cell.registeredAt.month == selectedMonth,
            )
            .toList();

    cellsInView.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

    return CellDashboardData(
      cellChartPoints: _visitDashboardService.buildChartPointsFromDates(
        dates: cellsInYear.map((cell) => cell.registeredAt).toList(),
        period: VisitChartPeriod.month,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
      cellsCreatedInRange: cellsInView.length,
      cellsInRange: cellsInView,
    );
  }

  Future<List<ChurchCell>> _fetchCells(String? churchId) async {
    final normalizedChurchId = churchId?.trim();
    Query<Map<String, dynamic>> query = _cells;
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: normalizedChurchId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(ChurchCell.fromFirestore).toList();
  }

  static String messageFromException(Object error, AppLocalizations l10n) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return l10n.cellDashboardDenied;
        case 'unavailable':
          return l10n.serviceUnavailable;
        default:
          return l10n.cellDashboardLoadError;
      }
    }
    return l10n.cellDashboardLoadError;
  }
}
