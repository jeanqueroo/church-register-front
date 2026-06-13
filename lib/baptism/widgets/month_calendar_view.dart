import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Calendario mensual simple con días resaltados.
class MonthCalendarView extends StatelessWidget {
  const MonthCalendarView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.markedDates,
    required this.onMonthChanged,
    required this.onDateSelected,
    this.weekdayLabels,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Set<DateTime> markedDates;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final List<String>? weekdayLabels;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(focusedMonth);
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final leadingEmpty = firstDay.weekday - 1;
    final labels = weekdayLabels ??
        const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    onMonthChanged(
                      DateTime(focusedMonth.year, focusedMonth.month - 1),
                    );
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    onMonthChanged(
                      DateTime(focusedMonth.year, focusedMonth.month + 1),
                    );
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: labels
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: leadingEmpty + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingEmpty) return const SizedBox.shrink();

                final day = index - leadingEmpty + 1;
                final date = DateTime(focusedMonth.year, focusedMonth.month, day);
                final dateOnly = _dateOnly(date);
                final isSelected = selectedDate != null &&
                    _dateOnly(selectedDate!) == dateOnly;
                final isToday = _dateOnly(DateTime.now()) == dateOnly;
                final hasEvent = markedDates.contains(dateOnly);

                return Material(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onDateSelected(dateOnly),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (hasEvent)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
