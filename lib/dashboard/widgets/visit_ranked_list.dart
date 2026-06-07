import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../models/visit_chart_point.dart';

class VisitRankedList extends StatelessWidget {
  const VisitRankedList({
    super.key,
    required this.items,
    this.emptyMessage,
  });

  final List<VisitChartPoint> items;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = emptyMessage ?? l10n.dashboardNoData;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      );
    }

    final maxCount = items.first.count;

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.bubbleOutgoing,
                      child: Text(
                        '${i + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('${items[i].count}'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primaryLight.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxCount == 0 ? 0 : items[i].count / maxCount,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
