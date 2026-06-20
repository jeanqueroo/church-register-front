import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';
import '../models/cell_attendance_session.dart';
import '../models/cell_member_attendance_summary.dart';
import '../models/church_cell.dart';
import '../services/cell_attendance_service.dart';
import '../utils/cell_attendance_summary_builder.dart';
import '../utils/cell_attendance_week_filter.dart';

class CellAttendanceOverviewScreen extends StatelessWidget {
  const CellAttendanceOverviewScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.permissions,
    this.actingLeaderId,
    this.attendanceService,
    this.memberService,
  });

  final ChurchCell cell;
  final String registeredBy;
  final AppPermissions? permissions;
  final String? actingLeaderId;
  final CellAttendanceService? attendanceService;
  final MemberService? memberService;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canViewCellAttendanceReport,
      deniedMessage: l10n.cellAttendanceReportDenied,
      child: _CellAttendanceOverviewBody(
        cell: cell,
        attendanceService: attendanceService ?? CellAttendanceService(),
        memberService: memberService ?? MemberService(),
      ),
    );
  }
}

class _CellAttendanceOverviewBody extends StatefulWidget {
  const _CellAttendanceOverviewBody({
    required this.cell,
    required this.attendanceService,
    required this.memberService,
  });

  final ChurchCell cell;
  final CellAttendanceService attendanceService;
  final MemberService memberService;

  @override
  State<_CellAttendanceOverviewBody> createState() =>
      _CellAttendanceOverviewBodyState();
}

class _CellAttendanceOverviewBodyState extends State<_CellAttendanceOverviewBody> {
  static const _defaultWeekCount = 4;

  bool _showAllWeeks = false;
  late DateTime _startWeek;
  late DateTime _endWeek;

  @override
  void initState() {
    super.initState();
    final (start, end) = lastNWeeksRange(_defaultWeekCount);
    _startWeek = start;
    _endWeek = end;
  }

  void _applyPresetWeeks(int weekCount) {
    final (start, end) = lastNWeeksRange(weekCount);
    setState(() {
      _showAllWeeks = false;
      _startWeek = start;
      _endWeek = end;
    });
  }

  void _applyAllWeeks() {
    setState(() => _showAllWeeks = true);
  }

  List<CellAttendanceSession> _filteredSessions(
    List<CellAttendanceSession> sessions,
  ) {
    if (_showAllWeeks) return sessions;
    return filterSessionsByWeekRange(
      sessions: sessions,
      startWeek: _startWeek,
      endWeek: _endWeek,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cellId = widget.cell.id;

    if (cellId == null || cellId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cellAttendanceReportTitle)),
        body: Center(child: Text(l10n.cellDiscipleCellMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellAttendanceReportTitle),
      ),
      body: StreamBuilder<List<ChurchMember>>(
        stream: widget.memberService.watchMembersInCell(cellId),
        builder: (context, membersSnapshot) {
          if (membersSnapshot.connectionState == ConnectionState.waiting &&
              !membersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<CellAttendanceSession>>(
            stream: widget.attendanceService.watchSessions(cellId),
            builder: (context, sessionsSnapshot) {
              if (sessionsSnapshot.connectionState == ConnectionState.waiting &&
                  !sessionsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = membersSnapshot.data ?? const [];
              final allSessions = sessionsSnapshot.data ?? const [];

              final filteredSessions = _filteredSessions(allSessions);
              final summaries = buildCellMemberAttendanceSummaries(
                members: members,
                sessions: filteredSessions,
              );
              final weekOptions = buildWeekOptions(sessions: allSessions);

              return _OverviewContent(
                cell: widget.cell,
                l10n: l10n,
                totalSessionCount: allSessions.length,
                filteredSessionCount: filteredSessions.length,
                summaries: summaries,
                weekOptions: weekOptions,
                showAllWeeks: _showAllWeeks,
                startWeek: _startWeek,
                endWeek: _endWeek,
                onPresetWeeks: _applyPresetWeeks,
                onShowAllWeeks: _applyAllWeeks,
                onStartWeekChanged: (week) {
                  setState(() {
                    _showAllWeeks = false;
                    _startWeek = week;
                    if (week.isAfter(_endWeek)) {
                      _endWeek = week;
                    }
                  });
                },
                onEndWeekChanged: (week) {
                  setState(() {
                    _showAllWeeks = false;
                    _endWeek = week;
                    if (week.isBefore(_startWeek)) {
                      _startWeek = week;
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.cell,
    required this.l10n,
    required this.totalSessionCount,
    required this.filteredSessionCount,
    required this.summaries,
    required this.weekOptions,
    required this.showAllWeeks,
    required this.startWeek,
    required this.endWeek,
    required this.onPresetWeeks,
    required this.onShowAllWeeks,
    required this.onStartWeekChanged,
    required this.onEndWeekChanged,
  });

  final ChurchCell cell;
  final AppLocalizations l10n;
  final int totalSessionCount;
  final int filteredSessionCount;
  final List<CellMemberAttendanceSummary> summaries;
  final List<DateTime> weekOptions;
  final bool showAllWeeks;
  final DateTime startWeek;
  final DateTime endWeek;
  final ValueChanged<int> onPresetWeeks;
  final VoidCallback onShowAllWeeks;
  final ValueChanged<DateTime> onStartWeekChanged;
  final ValueChanged<DateTime> onEndWeekChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.groups_2_outlined),
            title: Text(cell.displayLabel),
            subtitle: Text(
              [
                if (cell.leaderName != null && cell.leaderName!.trim().isNotEmpty)
                  cell.leaderName!,
                showAllWeeks
                    ? l10n.cellAttendanceReportSessionCount(totalSessionCount)
                    : l10n.cellAttendanceReportFilteredSessionCount(
                        filteredSessionCount,
                        totalSessionCount,
                      ),
              ].join(' · '),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _WeekRangeFilterCard(
          l10n: l10n,
          weekOptions: weekOptions,
          showAllWeeks: showAllWeeks,
          startWeek: startWeek,
          endWeek: endWeek,
          onPresetWeeks: onPresetWeeks,
          onShowAllWeeks: onShowAllWeeks,
          onStartWeekChanged: onStartWeekChanged,
          onEndWeekChanged: onEndWeekChanged,
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cellAttendanceReportLegendTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                _LegendRow(
                  color: Colors.green.shade700,
                  label: l10n.cellAttendanceReportLegendExcellent,
                ),
                const SizedBox(height: 4),
                _LegendRow(
                  color: Colors.amber.shade700,
                  label: l10n.cellAttendanceReportLegendWarning,
                ),
                const SizedBox(height: 4),
                _LegendRow(
                  color: Theme.of(context).colorScheme.error,
                  label: l10n.cellAttendanceReportLegendCritical,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.cellAttendanceReportMembersTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (summaries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.cellAttendanceReportEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...summaries.map(
            (summary) => _MemberAttendanceTile(
              l10n: l10n,
              summary: summary,
            ),
          ),
      ],
    );
  }
}

class _WeekRangeFilterCard extends StatelessWidget {
  const _WeekRangeFilterCard({
    required this.l10n,
    required this.weekOptions,
    required this.showAllWeeks,
    required this.startWeek,
    required this.endWeek,
    required this.onPresetWeeks,
    required this.onShowAllWeeks,
    required this.onStartWeekChanged,
    required this.onEndWeekChanged,
  });

  final AppLocalizations l10n;
  final List<DateTime> weekOptions;
  final bool showAllWeeks;
  final DateTime startWeek;
  final DateTime endWeek;
  final ValueChanged<int> onPresetWeeks;
  final VoidCallback onShowAllWeeks;
  final ValueChanged<DateTime> onStartWeekChanged;
  final ValueChanged<DateTime> onEndWeekChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveStart = startOfWeek(startWeek);
    final effectiveEnd = startOfWeek(endWeek);
    final options = weekOptions.isEmpty
        ? [effectiveStart, effectiveEnd]
        : weekOptions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.cellAttendanceReportWeekFilterTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(l10n.cellAttendanceReportWeekPreset(4)),
                  selected: !showAllWeeks &&
                      _matchesPreset(startWeek, endWeek, 4),
                  onSelected: (_) => onPresetWeeks(4),
                ),
                FilterChip(
                  label: Text(l10n.cellAttendanceReportWeekPreset(8)),
                  selected: !showAllWeeks &&
                      _matchesPreset(startWeek, endWeek, 8),
                  onSelected: (_) => onPresetWeeks(8),
                ),
                FilterChip(
                  label: Text(l10n.cellAttendanceReportWeekPreset(12)),
                  selected: !showAllWeeks &&
                      _matchesPreset(startWeek, endWeek, 12),
                  onSelected: (_) => onPresetWeeks(12),
                ),
                FilterChip(
                  label: Text(l10n.cellAttendanceReportWeekAll),
                  selected: showAllWeeks,
                  onSelected: (_) => onShowAllWeeks(),
                ),
              ],
            ),
            if (!showAllWeeks) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<DateTime>(
                initialValue: options.contains(effectiveStart)
                    ? effectiveStart
                    : options.first,
                decoration: InputDecoration(
                  labelText: l10n.cellAttendanceReportWeekFrom,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: options
                    .map(
                      (week) => DropdownMenuItem(
                        value: week,
                        child: Text(formatWeekRangeLabel(week)),
                      ),
                    )
                    .toList(),
                onChanged: (week) {
                  if (week != null) onStartWeekChanged(week);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DateTime>(
                initialValue: options.contains(effectiveEnd)
                    ? effectiveEnd
                    : options.last,
                decoration: InputDecoration(
                  labelText: l10n.cellAttendanceReportWeekTo,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: options
                    .map(
                      (week) => DropdownMenuItem(
                        value: week,
                        child: Text(formatWeekRangeLabel(week)),
                      ),
                    )
                    .toList(),
                onChanged: (week) {
                  if (week != null) onEndWeekChanged(week);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _matchesPreset(DateTime start, DateTime end, int weekCount) {
    final (expectedStart, expectedEnd) = lastNWeeksRange(weekCount);
    return startOfWeek(start) == expectedStart &&
        startOfWeek(end) == expectedEnd;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _MemberAttendanceTile extends StatelessWidget {
  const _MemberAttendanceTile({
    required this.l10n,
    required this.summary,
  });

  final AppLocalizations l10n;
  final CellMemberAttendanceSummary summary;

  Color? _tileColor(BuildContext context) {
    switch (summary.absenceAlert) {
      case CellMemberAbsenceAlert.excellent:
        return Colors.green.shade50;
      case CellMemberAbsenceAlert.warning:
        return Colors.amber.shade100;
      case CellMemberAbsenceAlert.critical:
        return Theme.of(context).colorScheme.errorContainer;
    }
  }

  Color? _avatarColor(BuildContext context) {
    switch (summary.absenceAlert) {
      case CellMemberAbsenceAlert.excellent:
        return Colors.green.shade700;
      case CellMemberAbsenceAlert.warning:
        return Colors.amber.shade700;
      case CellMemberAbsenceAlert.critical:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData? _trailingIcon() {
    switch (summary.absenceAlert) {
      case CellMemberAbsenceAlert.excellent:
        return Icons.check_circle_outline;
      case CellMemberAbsenceAlert.warning:
        return Icons.info_outline;
      case CellMemberAbsenceAlert.critical:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileColor = _tileColor(context);
    final avatarColor = _avatarColor(context);
    final trailingIcon = _trailingIcon();

    return Card(
      color: tileColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          foregroundColor: avatarColor != null ? Colors.white : null,
          child: Text(
            summary.fullName.isNotEmpty
                ? summary.fullName[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(summary.fullName),
        subtitle: Text(
          l10n.cellAttendanceReportMemberStats(
            summary.presentCount,
            summary.consecutiveAbsenceStreak,
            summary.rollCallCount,
          ),
        ),
        trailing: trailingIcon == null
            ? null
            : Icon(
                trailingIcon,
                color: avatarColor,
              ),
      ),
    );
  }
}
