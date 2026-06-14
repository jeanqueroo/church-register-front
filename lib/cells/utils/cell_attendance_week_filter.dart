import '../models/cell_attendance_session.dart';

/// Lunes como inicio de semana.
DateTime startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime endOfWeek(DateTime date) {
  return startOfWeek(date).add(const Duration(days: 6));
}

List<DateTime> buildWeekOptions({
  required List<CellAttendanceSession> sessions,
  int maxPastWeeks = 52,
}) {
  final nowWeek = startOfWeek(DateTime.now());
  var earliest = nowWeek.subtract(Duration(days: 7 * maxPastWeeks));

  for (final session in sessions) {
    final week = startOfWeek(session.sessionDate);
    if (week.isBefore(earliest)) earliest = week;
  }

  final weeks = <DateTime>[];
  var cursor = earliest;
  while (!cursor.isAfter(nowWeek)) {
    weeks.add(cursor);
    cursor = cursor.add(const Duration(days: 7));
  }
  return weeks;
}

List<CellAttendanceSession> filterSessionsByWeekRange({
  required List<CellAttendanceSession> sessions,
  required DateTime startWeek,
  required DateTime endWeek,
}) {
  final rangeStart = startOfWeek(startWeek);
  final rangeEnd = endOfWeek(endWeek);

  return sessions.where((session) {
    final day = DateTime(
      session.sessionDate.year,
      session.sessionDate.month,
      session.sessionDate.day,
    );
    return !day.isBefore(rangeStart) && !day.isAfter(rangeEnd);
  }).toList();
}

/// Últimas [weekCount] semanas incluyendo la semana actual.
(DateTime startWeek, DateTime endWeek) lastNWeeksRange(int weekCount) {
  final endWeek = startOfWeek(DateTime.now());
  final startWeek = endWeek.subtract(Duration(days: 7 * (weekCount - 1)));
  return (startWeek, endWeek);
}

String formatWeekDayMonth(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String formatWeekRangeLabel(DateTime weekStart) {
  final weekEnd = endOfWeek(weekStart);
  return '${formatWeekDayMonth(weekStart)} – ${formatWeekDayMonth(weekEnd)}';
}
