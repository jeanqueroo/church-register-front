enum CellMemberAbsenceAlert {
  excellent,
  warning,
  critical;

  static const int criticalAbsenceThreshold = 3;

  /// Basado en inasistencias **consecutivas** (desde la última reunión).
  static CellMemberAbsenceAlert fromConsecutiveAbsences(int streak) {
    if (streak >= criticalAbsenceThreshold) return CellMemberAbsenceAlert.critical;
    if (streak == 2) return CellMemberAbsenceAlert.warning;
    return CellMemberAbsenceAlert.excellent;
  }
}

class CellMemberAttendanceSummary {
  const CellMemberAttendanceSummary({
    required this.memberId,
    required this.fullName,
    required this.presentCount,
    required this.absentCount,
    required this.consecutiveAbsenceStreak,
  });

  final String memberId;
  final String fullName;
  final int presentCount;
  final int absentCount;
  final int consecutiveAbsenceStreak;

  int get rollCallCount => presentCount + absentCount;

  CellMemberAbsenceAlert get absenceAlert =>
      CellMemberAbsenceAlert.fromConsecutiveAbsences(consecutiveAbsenceStreak);
}
