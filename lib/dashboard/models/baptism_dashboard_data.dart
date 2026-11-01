import '../../members/models/church_member.dart';
import 'visit_chart_point.dart';

class BaptismDashboardData {
  const BaptismDashboardData({
    required this.baptismChartPoints,
    required this.baptizedInRange,
    required this.newBelieversBaptizedInRange,
    required this.baptizedMembersInRange,
  });

  final List<VisitChartPoint> baptismChartPoints;
  final int baptizedInRange;
  final int newBelieversBaptizedInRange;
  final List<ChurchMember> baptizedMembersInRange;
}
