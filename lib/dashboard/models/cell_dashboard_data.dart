import '../../cells/models/church_cell.dart';
import 'visit_chart_point.dart';

class CellDashboardData {
  const CellDashboardData({
    required this.cellChartPoints,
    required this.cellsCreatedInRange,
    required this.cellsInRange,
  });

  final List<VisitChartPoint> cellChartPoints;
  final int cellsCreatedInRange;
  final List<ChurchCell> cellsInRange;
}
