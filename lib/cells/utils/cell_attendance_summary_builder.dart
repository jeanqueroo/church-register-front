import '../../members/models/church_member.dart';
import '../models/cell_attendance_record.dart';
import '../models/cell_attendance_session.dart';
import '../models/cell_member_attendance_summary.dart';

/// Inasistencias consecutivas desde la reunión más reciente hacia atrás.
int consecutiveAbsenceStreak({
  required String memberId,
  required List<CellAttendanceSession> sessions,
}) {
  final sorted = [...sessions]
    ..sort((a, b) {
      final byDate = b.sessionDate.compareTo(a.sessionDate);
      if (byDate != 0) return byDate;
      return b.sessionTime.compareTo(a.sessionTime);
    });

  var streak = 0;
  for (final session in sorted) {
    final record = _recordForMember(session.records, memberId);
    if (record == null) continue;
    if (record.present) break;
    streak++;
  }
  return streak;
}

CellAttendanceRecord? _recordForMember(
  List<CellAttendanceRecord> records,
  String memberId,
) {
  for (final record in records) {
    if (record.memberId.trim() == memberId) return record;
  }
  return null;
}

List<CellMemberAttendanceSummary> buildCellMemberAttendanceSummaries({
  required List<ChurchMember> members,
  required List<CellAttendanceSession> sessions,
}) {
  final presentByMember = <String, int>{};
  final absentByMember = <String, int>{};
  final namesByMember = <String, String>{};

  for (final member in members) {
    final id = member.id?.trim();
    if (id == null || id.isEmpty) continue;
    presentByMember[id] = 0;
    absentByMember[id] = 0;
    namesByMember[id] = member.fullName;
  }

  for (final session in sessions) {
    for (final record in session.records) {
      final id = record.memberId.trim();
      if (id.isEmpty || !presentByMember.containsKey(id)) continue;
      if (record.present) {
        presentByMember[id] = (presentByMember[id] ?? 0) + 1;
      } else {
        absentByMember[id] = (absentByMember[id] ?? 0) + 1;
      }
    }
  }

  final summaries = namesByMember.entries.map((entry) {
    final id = entry.key;
    return CellMemberAttendanceSummary(
      memberId: id,
      fullName: entry.value,
      presentCount: presentByMember[id] ?? 0,
      absentCount: absentByMember[id] ?? 0,
      consecutiveAbsenceStreak: consecutiveAbsenceStreak(
        memberId: id,
        sessions: sessions,
      ),
    );
  }).toList();

  summaries.sort((a, b) {
    final byStreak =
        b.consecutiveAbsenceStreak.compareTo(a.consecutiveAbsenceStreak);
    if (byStreak != 0) return byStreak;
    final byAbsences = b.absentCount.compareTo(a.absentCount);
    if (byAbsences != 0) return byAbsences;
    return a.fullName.compareTo(b.fullName);
  });

  return summaries;
}

/// Críticos solo desde listas de asistencia (sin leer la colección members).
List<CellMemberAttendanceSummary> buildCriticalAbsencesFromSessions({
  required List<CellAttendanceSession> sessions,
  int minConsecutiveAbsences =
      CellMemberAbsenceAlert.criticalAbsenceThreshold,
}) {
  if (sessions.length < minConsecutiveAbsences) return const [];

  final sorted = [...sessions]
    ..sort((a, b) {
      final byDate = b.sessionDate.compareTo(a.sessionDate);
      if (byDate != 0) return byDate;
      return b.sessionTime.compareTo(a.sessionTime);
    });

  final namesByMember = <String, String>{};
  final presentByMember = <String, int>{};
  final absentByMember = <String, int>{};

  for (final session in sorted) {
    for (final record in session.records) {
      final id = record.memberId.trim();
      if (id.isEmpty) continue;
      namesByMember.putIfAbsent(
        id,
        () => record.fullName.trim().isEmpty ? id : record.fullName.trim(),
      );
      if (record.present) {
        presentByMember[id] = (presentByMember[id] ?? 0) + 1;
      } else {
        absentByMember[id] = (absentByMember[id] ?? 0) + 1;
      }
    }
  }

  final critical = <CellMemberAttendanceSummary>[];
  for (final entry in namesByMember.entries) {
    final streak = consecutiveAbsenceStreak(
      memberId: entry.key,
      sessions: sorted,
    );
    if (streak < minConsecutiveAbsences) continue;
    critical.add(
      CellMemberAttendanceSummary(
        memberId: entry.key,
        fullName: entry.value,
        presentCount: presentByMember[entry.key] ?? 0,
        absentCount: absentByMember[entry.key] ?? 0,
        consecutiveAbsenceStreak: streak,
      ),
    );
  }

  critical.sort((a, b) {
    final byStreak =
        b.consecutiveAbsenceStreak.compareTo(a.consecutiveAbsenceStreak);
    if (byStreak != 0) return byStreak;
    return a.fullName.compareTo(b.fullName);
  });
  return critical;
}
