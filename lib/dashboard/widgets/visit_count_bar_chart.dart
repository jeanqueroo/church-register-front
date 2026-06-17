import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
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

  static const _minSlotWidth = 36.0;
  static const _maxSlotWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = _chartHeight(context);
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;

        if (points.isEmpty) {
          return SizedBox(
            height: chartHeight,
            width: availableWidth,
            child: Center(child: Text(l10n.dashboardNoData)),
          );
        }

        final layout = _resolveLayout(
          pointCount: points.length,
          availableWidth: availableWidth,
        );

        final chart = SizedBox(
          width: layout.chartWidth,
          height: chartHeight,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 8),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: layout.maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      layout.maxY <= 5 ? 1 : (layout.maxY / 5).ceilToDouble(),
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
                      reservedSize: layout.bottomReservedSize,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % layout.labelStep != 0 &&
                            index != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: layout.slotWidth,
                            child: Text(
                              points[index].label,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                          width: layout.barWidth,
                          color: const Color(0xFF1976D2),
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
                        '${point.label}\n${point.count}',
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

        if (!layout.needsHorizontalScroll) {
          return chart;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: chart,
        );
      },
    );
  }

  double _chartHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight * 0.28).clamp(220.0, 340.0);
  }

  _ChartLayout _resolveLayout({
    required int pointCount,
    required double availableWidth,
  }) {
    final maxCount = points.map((point) => point.count).reduce(
          (a, b) => a > b ? a : b,
        );
    final maxY = maxCount == 0 ? 1.0 : (maxCount * 1.2).ceilToDouble();

    if (pointCount == 0) {
      return _ChartLayout(
        chartWidth: availableWidth,
        slotWidth: availableWidth,
        barWidth: 16,
        maxY: maxY,
        labelStep: 1,
        bottomReservedSize: period == VisitChartPeriod.day ? 36 : 42,
        needsHorizontalScroll: false,
      );
    }

    final naturalSlotWidth = availableWidth / pointCount;
    final slotWidth = naturalSlotWidth.clamp(_minSlotWidth, _maxSlotWidth);
    final chartWidth = slotWidth * pointCount;
    final needsHorizontalScroll = chartWidth > availableWidth + 1;
    final barWidth = (slotWidth * 0.55).clamp(8.0, 24.0);
    final labelStep = _labelStep(
      pointCount: pointCount,
      slotWidth: slotWidth,
      needsHorizontalScroll: needsHorizontalScroll,
    );
    final bottomReservedSize = period == VisitChartPeriod.day
        ? 36.0
        : slotWidth < 44
            ? 52.0
            : 42.0;

    return _ChartLayout(
      chartWidth: needsHorizontalScroll ? chartWidth : availableWidth,
      slotWidth: slotWidth,
      barWidth: barWidth,
      maxY: maxY,
      labelStep: labelStep,
      bottomReservedSize: bottomReservedSize,
      needsHorizontalScroll: needsHorizontalScroll,
    );
  }

  int _labelStep({
    required int pointCount,
    required double slotWidth,
    required bool needsHorizontalScroll,
  }) {
    if (pointCount <= 1) return 1;
    if (!needsHorizontalScroll && slotWidth >= 44) return 1;
    if (pointCount <= 8) return 1;
    if (pointCount <= 12) return needsHorizontalScroll ? 1 : 2;
    return (pointCount / 6).ceil();
  }
}

class _ChartLayout {
  const _ChartLayout({
    required this.chartWidth,
    required this.slotWidth,
    required this.barWidth,
    required this.maxY,
    required this.labelStep,
    required this.bottomReservedSize,
    required this.needsHorizontalScroll,
  });

  final double chartWidth;
  final double slotWidth;
  final double barWidth;
  final double maxY;
  final int labelStep;
  final double bottomReservedSize;
  final bool needsHorizontalScroll;
}
