import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../members/models/member_visit.dart';
import '../models/visit_chart_point.dart';
import '../models/visit_dashboard_filter.dart';

class VisitDashboardService {
  VisitDashboardService({FirebaseFirestore? firestore})
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

  Future<List<MemberVisit>> fetchVisits({
    required VisitDashboardFilter filter,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final leaderIds = filter.leaderIds;
    if (leaderIds != null) {
      if (leaderIds.isEmpty) return [];
      return _fetchVisitsByLeaders(
        leaderIds: leaderIds,
        churchId: filter.churchId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }

    Query<Map<String, dynamic>> query = _firestore.collectionGroup('visits');

    final churchId = filter.churchId?.trim();
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }

    query = query
        .where(
          'visitDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart),
        )
        .where(
          'visitDate',
          isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd),
        );

    final snapshot = await query.get();
    return snapshot.docs.map(MemberVisit.fromFirestore).toList();
  }

  /// Supervisor: consulta por `leaderId` (máx. 10 por query en Firestore).
  Future<List<MemberVisit>> _fetchVisitsByLeaders({
    required Set<String> leaderIds,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    String? churchId,
  }) async {
    final ids = leaderIds.toList()..sort();
    final visits = <MemberVisit>[];
    const batchSize = 10;
    final batchFutures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];

    for (var i = 0; i < ids.length; i += batchSize) {
      final end = i + batchSize > ids.length ? ids.length : i + batchSize;
      final batch = ids.sublist(i, end);

      batchFutures.add(
        _firestore
            .collectionGroup('visits')
            .where('leaderId', whereIn: batch)
            .where(
              'visitDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart),
            )
            .where(
              'visitDate',
              isLessThanOrEqualTo: Timestamp.fromDate(rangeEnd),
            )
            .get(),
      );
    }

    final snapshots = await Future.wait(batchFutures);
    for (final snapshot in snapshots) {
      visits.addAll(snapshot.docs.map(MemberVisit.fromFirestore));
    }

    final normalizedChurchId = churchId?.trim();
    if (normalizedChurchId == null || normalizedChurchId.isEmpty) {
      return visits;
    }

    return visits
        .where((visit) => visit.churchId == normalizedChurchId)
        .toList();
  }

  List<VisitChartPoint> buildChartPoints({
    required List<MemberVisit> visits,
    required VisitChartPeriod period,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return buildChartPointsFromDates(
      dates: visits.map((visit) => visit.visitDate).toList(),
      period: period,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  List<VisitChartPoint> buildChartPointsFromDates({
    required List<DateTime> dates,
    required VisitChartPeriod period,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    switch (period) {
      case VisitChartPeriod.day:
        return _bucketByDay(dates, rangeStart, rangeEnd);
      case VisitChartPeriod.month:
        return _bucketByMonth(dates, rangeStart, rangeEnd);
      case VisitChartPeriod.year:
        return _bucketByYear(dates, rangeStart, rangeEnd);
    }
  }

  DateTime rangeStartFor(VisitChartPeriod period, DateTime now) {
    switch (period) {
      case VisitChartPeriod.day:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 13));
        return start;
      case VisitChartPeriod.month:
        return rangeStartForMonthCount(12, now);
      case VisitChartPeriod.year:
        return DateTime(now.year - 4, 1, 1);
    }
  }

  DateTime rangeStartForMonthCount(int monthCount, DateTime now) {
    if (monthCount < 1) {
      throw ArgumentError.value(monthCount, 'monthCount', 'must be >= 1');
    }
    var month = now.month - (monthCount - 1);
    var year = now.year;
    while (month <= 0) {
      month += 12;
      year--;
    }
    return DateTime(year, month, 1);
  }

  DateTime rangeEndFor(VisitChartPeriod period, DateTime now) {
    switch (period) {
      case VisitChartPeriod.day:
        return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      case VisitChartPeriod.month:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      case VisitChartPeriod.year:
        return DateTime(now.year, 12, 31, 23, 59, 59, 999);
    }
  }

  List<VisitChartPoint> _bucketByDay(
    List<DateTime> dates,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final dayFormat = DateFormat('dd/MM');
    final startDay = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final endDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    final counts = <int, int>{};
    final labels = <int, String>{};

    var cursor = startDay;
    while (!cursor.isAfter(endDay)) {
      final key = _dayKey(cursor);
      counts[key] = 0;
      labels[key] = dayFormat.format(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    for (final date in dates) {
      final key = _dayKey(date);
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return counts.entries
        .map(
          (entry) => VisitChartPoint(
            label: labels[entry.key] ?? '',
            count: entry.value,
            sortKey: entry.key,
          ),
        )
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  List<VisitChartPoint> _bucketByMonth(
    List<DateTime> dates,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final counts = <int, int>{};
    final labels = <int, String>{};

    var year = rangeStart.year;
    var month = rangeStart.month;
    final endKey = rangeEnd.year * 100 + rangeEnd.month;

    while (year * 100 + month <= endKey) {
      final key = year * 100 + month;
      counts[key] = 0;
      labels[key] = _monthLabel(year, month);
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }

    for (final date in dates) {
      final key = date.year * 100 + date.month;
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    return counts.entries
        .map(
          (entry) => VisitChartPoint(
            label: labels[entry.key] ?? '',
            count: entry.value,
            sortKey: entry.key,
          ),
        )
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  List<VisitChartPoint> _bucketByYear(
    List<DateTime> dates,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final counts = <int, int>{};
    for (var year = rangeStart.year; year <= rangeEnd.year; year++) {
      counts[year] = 0;
    }

    for (final date in dates) {
      final year = date.year;
      if (counts.containsKey(year)) {
        counts[year] = (counts[year] ?? 0) + 1;
      }
    }

    return counts.entries
        .map(
          (entry) => VisitChartPoint(
            label: '${entry.key}',
            count: entry.value,
            sortKey: entry.key,
          ),
        )
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  Map<String, int> countByLeader(List<MemberVisit> visits) {
    final counts = <String, int>{};
    for (final visit in visits) {
      final leaderId = visit.leaderId.trim();
      if (leaderId.isEmpty) continue;
      counts[leaderId] = (counts[leaderId] ?? 0) + 1;
    }
    return counts;
  }

  /// Lugares de visita más frecuentes (Casa, Hospital, etc.).
  List<VisitChartPoint> countByVisitPlace(List<MemberVisit> visits) {
    final counts = <String, int>{};
    for (final visit in visits) {
      final label = visit.visitPlace.label;
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (var i = 0; i < entries.length; i++)
        VisitChartPoint(
          label: entries[i].key,
          count: entries[i].value,
          sortKey: i,
        ),
    ];
  }

  /// Peticiones de oración más repetidas en el período.
  List<VisitChartPoint> countCommonPrayerRequests(
    List<MemberVisit> visits, {
    int limit = 10,
  }) {
    final counts = <String, int>{};
    final displayLabels = <String, String>{};

    for (final visit in visits) {
      for (final phrase in _splitPrayerRequests(visit.prayerRequests)) {
        final key = phrase.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
        displayLabels.putIfAbsent(key, () => phrase);
      }
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (var i = 0; i < entries.length && i < limit; i++)
        VisitChartPoint(
          label: displayLabels[entries[i].key] ?? entries[i].key,
          count: entries[i].value,
          sortKey: i,
        ),
    ];
  }

  static List<String> _splitPrayerRequests(String? text) {
    if (text == null || text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'[,;\n]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  int _dayKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  String _monthLabel(int year, int month) {
    final yy = (year % 100).toString().padLeft(2, '0');
    return '${_shortMonths[month - 1]} $yy';
  }

  static String messageFromException(Object e, AppLocalizations l10n) {
    if (e is StateError && e.message.isNotEmpty) {
      return e.message;
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return l10n.visitDashboardPermissionDenied;
        case 'failed-precondition':
          final message = e.message?.toLowerCase() ?? '';
          if (message.contains('building')) {
            return l10n.visitDashboardIndexBuilding;
          }
          return l10n.visitDashboardIndexMissing;
        case 'unavailable':
          return l10n.serviceUnavailable;
        default:
          return l10n.visitDashboardLoadError(e.message ?? e.code);
      }
    }
    final detail = e.toString().trim();
    if (detail.contains('LocaleDataException')) {
      return l10n.visitDashboardDateFormatError;
    }
    if (detail.isEmpty) {
      return l10n.visitDashboardLoadUnexpected('${e.runtimeType}');
    }
    return l10n.visitDashboardLoadError(detail);
  }
}
