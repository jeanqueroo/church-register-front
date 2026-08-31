import '../../l10n/app_localizations.dart';

enum OfferingChartPeriod {
  week,
  month,
  year;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case OfferingChartPeriod.week:
        return l10n.chartPeriodWeek;
      case OfferingChartPeriod.month:
        return l10n.chartPeriodMonth;
      case OfferingChartPeriod.year:
        return l10n.chartPeriodYear;
    }
  }
}

class OfferingChartPoint {
  const OfferingChartPoint({
    required this.label,
    required this.amount,
    required this.sortKey,
  });

  final String label;
  final double amount;
  final int sortKey;
}

class OfferingCellTotal {
  const OfferingCellTotal({
    required this.cellCode,
    required this.cash,
    required this.transfer,
  });

  final String cellCode;
  final double cash;
  final double transfer;

  double get total => cash + transfer;
}
