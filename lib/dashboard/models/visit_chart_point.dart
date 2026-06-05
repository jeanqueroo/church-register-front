class VisitChartPoint {
  const VisitChartPoint({
    required this.label,
    required this.count,
    required this.sortKey,
  });

  final String label;
  final int count;
  final int sortKey;
}

enum VisitChartPeriod {
  day,
  month,
  year;

  String get label {
    switch (this) {
      case VisitChartPeriod.day:
        return 'Por día';
      case VisitChartPeriod.month:
        return 'Por mes';
      case VisitChartPeriod.year:
        return 'Por año';
    }
  }
}
