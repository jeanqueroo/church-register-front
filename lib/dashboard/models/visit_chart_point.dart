import '../../l10n/app_localizations.dart';

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

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case VisitChartPeriod.day:
        return l10n.chartPeriodDay;
      case VisitChartPeriod.month:
        return l10n.chartPeriodMonth;
      case VisitChartPeriod.year:
        return l10n.chartPeriodYear;
    }
  }
}
