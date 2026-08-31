import 'offering_chart_period.dart';

class OfferingDashboardData {
  const OfferingDashboardData({
    required this.cashTotal,
    required this.transferTotal,
    required this.sessionCount,
    required this.chartPoints,
    required this.byCell,
  });

  final double cashTotal;
  final double transferTotal;
  final int sessionCount;
  final List<OfferingChartPoint> chartPoints;
  final List<OfferingCellTotal> byCell;

  double get grandTotal => cashTotal + transferTotal;
}
