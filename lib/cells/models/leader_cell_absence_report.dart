import 'cell_member_attendance_summary.dart';

class LeaderCellAbsenceReport {
  const LeaderCellAbsenceReport({
    required this.leaderId,
    required this.leaderName,
    required this.cellCode,
    required this.cellId,
    required this.totalDisciples,
    required this.criticalDisciples,
  });

  final String leaderId;
  final String leaderName;
  final String cellCode;
  final String cellId;
  final int totalDisciples;
  final List<CellMemberAttendanceSummary> criticalDisciples;

  int get criticalCount => criticalDisciples.length;
}
