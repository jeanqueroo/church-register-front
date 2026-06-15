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
    this.churchName,
    this.birthdaysToday = const [],
  });

  final int memberCount;
  final int newBelieverCount;
  final int? leaderCount;
  final String? churchName;
  final List<CellBirthdayPerson> birthdaysToday;
}
