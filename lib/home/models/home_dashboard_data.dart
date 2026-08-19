class CellBirthdayPerson {
  const CellBirthdayPerson({
    required this.name,
    this.age,
    this.cellCode,
  });

  final String name;
  final int? age;
  final String? cellCode;
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.memberCount,
    this.newBelieverCount = 0,
    this.leaderCount,
    this.cellCount,
    this.baptismCount,
    this.churchName,
    this.birthdaysToday = const [],
    this.hasOwnCell = false,
    this.ownCellDiscipleCount,
  });

  final int memberCount;
  final int newBelieverCount;
  final int? leaderCount;
  final int? cellCount;
  final int? baptismCount;
  final String? churchName;
  final List<CellBirthdayPerson> birthdaysToday;

  /// True when the user leads at least one cell (supervisor home disciples card).
  final bool hasOwnCell;

  /// Discípulos en la célula del propio líder (admin con rol líder/supervisor).
  final int? ownCellDiscipleCount;

  int get ownCellDisciplesForSummary => ownCellDiscipleCount ?? memberCount;
}
