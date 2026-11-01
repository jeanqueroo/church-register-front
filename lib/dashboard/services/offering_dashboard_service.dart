import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../cells/models/cell_attendance_session.dart';
import '../../l10n/app_localizations.dart';
import '../models/offering_chart_period.dart';
import '../models/offering_dashboard_data.dart';
import '../utils/offering_amount_parser.dart';

class OfferingDashboardService {
  OfferingDashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _shortMonths = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  Future<OfferingDashboardData> load({
    required OfferingChartPeriod period,
    String? churchId,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();
    final rangeStart = rangeStartFor(period, reference);
    final rangeEnd = rangeEndFor(period, reference);
    final sessions = await fetchSessions(
      churchId: churchId,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    var cashTotal = 0.0;
    var transferTotal = 0.0;
    final amountsByDate = <DateTime, double>{};
    final byCell = <String, ({double cash, double transfer})>{};

    for (final session in sessions) {
      final amounts = _amountsFromSession(session);
      if (amounts.cash == 0 && amounts.transfer == 0) continue;

      cashTotal += amounts.cash;
      transferTotal += amounts.transfer;

      final day = DateTime(
        session.sessionDate.year,
        session.sessionDate.month,
        session.sessionDate.day,
      );
      amountsByDate[day] = (amountsByDate[day] ?? 0) + amounts.total;

      final cellCode = session.cellCode.trim().isEmpty
          ? session.cellId.trim()
          : session.cellCode.trim();
      if (cellCode.isEmpty) continue;
      final current = byCell[cellCode];
      byCell[cellCode] = (
        cash: (current?.cash ?? 0) + amounts.cash,
        transfer: (current?.transfer ?? 0) + amounts.transfer,
      );
    }

    final chartPoints = _buildChartPoints(
      amountsByDate: amountsByDate,
      period: period,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    final cellTotals = byCell.entries
        .map(
          (entry) => OfferingCellTotal(
            cellCode: entry.key,
            cash: entry.value.cash,
            transfer: entry.value.transfer,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return OfferingDashboardData(
      cashTotal: cashTotal,
      transferTotal: transferTotal,
      sessionCount: sessions.length,
      chartPoints: chartPoints,
      byCell: cellTotals,
    );
  }

  Future<List<CellAttendanceSession>> fetchSessions({
    String? churchId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collectionGroup('sessions');

    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId != null && normalizedChurchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: normalizedChurchId);
    }

    query = query
        .where(
          'sessionDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart),
        )
        .where(
          'sessionDate',
          isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd),
        );

    final snapshot = await query.get();
    final sessions = snapshot.docs
        .map(CellAttendanceSession.fromFirestore)
        .toList();

    if (normalizedChurchId == null || normalizedChurchId.isEmpty) {
      return sessions;
    }

    return sessions
        .where(
          (session) =>
              session.churchId == null ||
              session.churchId!.trim().isEmpty ||
              session.churchId == normalizedChurchId,
        )
        .toList();
  }

  DateTime rangeStartFor(OfferingChartPeriod period, DateTime now) {
    switch (period) {
      case OfferingChartPeriod.week:
        final today = DateTime(now.year, now.month, now.day);
        return today.subtract(const Duration(days: 6));
      case OfferingChartPeriod.month:
        return DateTime(now.year, now.month, 1);
      case OfferingChartPeriod.year:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime rangeEndFor(OfferingChartPeriod period, DateTime now) {
    switch (period) {
      case OfferingChartPeriod.week:
        return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      case OfferingChartPeriod.month:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      case OfferingChartPeriod.year:
        return DateTime(now.year, 12, 31, 23, 59, 59, 999);
    }
  }

  String periodLabel(OfferingChartPeriod period, DateTime now) {
    switch (period) {
      case OfferingChartPeriod.week:
        final start = rangeStartFor(period, now);
        final dayFormat = DateFormat('dd/MM');
        return '${dayFormat.format(start)} – ${dayFormat.format(now)}';
      case OfferingChartPeriod.month:
        return DateFormat('MMMM yyyy').format(now);
      case OfferingChartPeriod.year:
        return '${now.year}';
    }
  }

  List<OfferingChartPoint> _buildChartPoints({
    required Map<DateTime, double> amountsByDate,
    required OfferingChartPeriod period,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    switch (period) {
      case OfferingChartPeriod.week:
      case OfferingChartPeriod.month:
        return _bucketByDay(amountsByDate, rangeStart, rangeEnd);
      case OfferingChartPeriod.year:
        return _bucketByMonth(amountsByDate, rangeStart, rangeEnd);
    }
  }

  List<OfferingChartPoint> _bucketByDay(
    Map<DateTime, double> amountsByDate,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final dayFormat = DateFormat('dd/MM');
    final startDay = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final endDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    final points = <OfferingChartPoint>[];

    var cursor = startDay;
    while (!cursor.isAfter(endDay)) {
      final key = DateTime(cursor.year, cursor.month, cursor.day);
      points.add(
        OfferingChartPoint(
          label: dayFormat.format(cursor),
          amount: amountsByDate[key] ?? 0,
          sortKey: _dayKey(cursor),
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    return points;
  }

  List<OfferingChartPoint> _bucketByMonth(
    Map<DateTime, double> amountsByDate,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final totals = <int, double>{};
    final labels = <int, String>{};

    var year = rangeStart.year;
    var month = rangeStart.month;
    final endKey = rangeEnd.year * 100 + rangeEnd.month;

    while (year * 100 + month <= endKey) {
      final key = year * 100 + month;
      totals[key] = 0;
      labels[key] = _monthLabel(year, month);
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    for (final entry in amountsByDate.entries) {
      final key = entry.key.year * 100 + entry.key.month;
      if (totals.containsKey(key)) {
        totals[key] = (totals[key] ?? 0) + entry.value;
      }
    }

    return totals.entries
        .map(
          (entry) => OfferingChartPoint(
            label: labels[entry.key] ?? '',
            amount: entry.value,
            sortKey: entry.key,
          ),
        )
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  ({double cash, double transfer, double total}) _amountsFromSession(
    CellAttendanceSession session,
  ) {
    var cash = parseOfferingAmount(session.offeringCash);
    var transfer = parseOfferingAmount(session.offeringTransfer);
    if (cash == 0 && transfer == 0) {
      cash = parseOfferingAmount(session.offeringCollected);
    }
    return (cash: cash, transfer: transfer, total: cash + transfer);
  }

  int _dayKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  String _monthLabel(int year, int month) {
    if (month < 1 || month > 12) return '$month/$year';
    return '${_shortMonths[month - 1]} $year';
  }

  static String formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat('#,##0', 'es').format(amount.round());
    }
    return NumberFormat('#,##0.##', 'es').format(amount);
  }

  static String messageFromException(Object error, AppLocalizations l10n) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return l10n.firestorePermissionDenied;
        case 'failed-precondition':
          return l10n.offeringDashboardIndexHint;
        case 'unavailable':
          return l10n.firestoreUnavailable;
        default:
          return l10n.firestoreGenericError;
      }
    }
    return l10n.serviceGenericError;
  }
}
