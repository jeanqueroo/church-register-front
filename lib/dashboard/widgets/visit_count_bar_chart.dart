import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../models/visit_chart_point.dart';

class VisitCountBarChart extends StatelessWidget {
  const VisitCountBarChart({
    super.key,
    required this.points,
    required this.period,
  });

  final List<VisitChartPoint> points;
  final VisitChartPeriod period;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Sin datos para mostrar')),
      );
    }

    final maxCount = points.map((p) => p.count).reduce((a, b) => a > b ? a : b);
    final maxY = maxCount == 0 ? 1.0 : (maxCount * 1.2).ceilToDouble();
    final showEveryNthLabel = points.length > 8 ? (points.length / 6).ceil() : 1;

    return SizedBox(
      height: 260,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY <= 5 ? 1 : (maxY / 5).ceilToDouble(),
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.divider,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    if (value != value.roundToDouble()) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: period == VisitChartPeriod.day ? 36 : 42,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    if (index % showEveryNthLabel != 0 &&
                        index != points.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        points[index].label,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < points.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: points[i].count.toDouble(),
                      width: points.length > 10 ? 10 : 16,
                      color: AppColors.primaryLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
            ],
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final point = points[group.x];
                  return BarTooltipItem(
                    '${point.label}\n${point.count} visita'
                    '${point.count == 1 ? '' : 's'}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
