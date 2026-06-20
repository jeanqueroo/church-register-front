import '../../leaders/models/church_leader.dart';
import 'visit_chart_point.dart';

class LeaderDashboardData {
  const LeaderDashboardData({
    required this.leaderChartPoints,
    required this.leadersCreatedInRange,
    required this.leadersFromRegisterLeaderInRange,
    required this.leadersFromCellInRange,
    required this.leadersInRange,
  });

  final List<VisitChartPoint> leaderChartPoints;
  final int leadersCreatedInRange;
  final int leadersFromRegisterLeaderInRange;
  final int leadersFromCellInRange;
  final List<ChurchLeader> leadersInRange;
}
