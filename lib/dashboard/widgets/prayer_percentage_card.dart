import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../services/pastoral_dashboard_service.dart';

class PrayerPercentageCard extends StatelessWidget {
  const PrayerPercentageCard({
    super.key,
    required this.stats,
  });

  final PrayerVisitStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final percentage = stats.percentage;
    final displayPercent = percentage == percentage.roundToDouble()
        ? '${percentage.round()}%'
        : '${percentage.toStringAsFixed(1)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.volunteer_activism_outlined, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.dashboardPrayerVisitsTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              displayPercent,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stats.totalVisits == 0 ? 0 : percentage / 100,
                minHeight: 10,
                backgroundColor: AppColors.divider,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              stats.totalVisits == 0
                  ? l10n.dashboardPrayerVisitsEmpty
                  : l10n.dashboardPrayerVisitsSummary(
                      stats.prayerVisits,
                      stats.totalVisits,
                    ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
