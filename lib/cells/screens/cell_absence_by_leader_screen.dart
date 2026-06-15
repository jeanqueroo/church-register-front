import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../models/cell_member_attendance_summary.dart';
import '../models/leader_cell_absence_report.dart';
import '../services/cell_absence_by_leader_service.dart';

class CellAbsenceByLeaderScreen extends StatefulWidget {
  const CellAbsenceByLeaderScreen({
    super.key,
    required this.churchId,
    this.permissions,
    this.reportService,
  });

  final String? churchId;
  final AppPermissions? permissions;
  final CellAbsenceByLeaderService? reportService;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<CellAbsenceByLeaderScreen> createState() =>
      _CellAbsenceByLeaderScreenState();
}

class _CellAbsenceByLeaderScreenState extends State<CellAbsenceByLeaderScreen> {
  late final CellAbsenceByLeaderService _reportService;

  List<LeaderCellAbsenceReport> _reports = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _reportService = widget.reportService ?? CellAbsenceByLeaderService();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final churchId = widget.churchId?.trim();
    if (churchId == null || churchId.isEmpty) {
      setState(() {
        _reports = [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final reports = await _reportService.loadForChurch(churchId);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = context.l10n.cellAbsenceByLeaderLoadError;
        _loading = false;
      });
    }
  }

  int get _totalCriticalDisciples => _reports.fold<int>(
        0,
        (sum, report) => sum + report.criticalCount,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final churchId = widget.churchId?.trim();

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canViewCellAbsenceByLeader,
      deniedMessage: l10n.cellAbsenceByLeaderDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.cellAbsenceByLeaderTitle),
        ),
        body: churchId == null || churchId.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.cellAbsenceByLeaderNoChurch,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _buildBody(context, l10n),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadReports,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.cellAbsenceByLeaderEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.cellAttendanceReportLegendCritical,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (_totalCriticalDisciples > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.cellAbsenceByLeaderTotalCritical(
                        _totalCriticalDisciples,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._reports.map(
            (report) => _LeaderAbsenceCard(
              l10n: l10n,
              report: report,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderAbsenceCard extends StatelessWidget {
  const _LeaderAbsenceCard({
    required this.l10n,
    required this.report,
  });

  final AppLocalizations l10n;
  final LeaderCellAbsenceReport report;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final hasCritical = report.criticalCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: hasCritical,
          leading: CircleAvatar(
            backgroundColor:
                hasCritical ? errorColor : Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: Text(
              report.leaderName.isNotEmpty
                  ? report.leaderName[0].toUpperCase()
                  : '?',
            ),
          ),
          title: Text(report.leaderName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cellAbsenceByLeaderCellLabel(report.cellCode)),
              const SizedBox(height: 4),
              Text(
                l10n.cellAbsenceByLeaderCriticalCount(report.criticalCount),
                style: TextStyle(
                  color: hasCritical ? errorColor : null,
                  fontWeight: hasCritical ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
          children: [
            if (report.criticalDisciples.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.cellAbsenceByLeaderLeaderOk,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...report.criticalDisciples.map(
                (summary) => _CriticalDiscipleTile(
                  l10n: l10n,
                  summary: summary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CriticalDiscipleTile extends StatelessWidget {
  const _CriticalDiscipleTile({
    required this.l10n,
    required this.summary,
  });

  final AppLocalizations l10n;
  final CellMemberAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return ListTile(
      dense: true,
      tileColor: Theme.of(context).colorScheme.errorContainer.withValues(
            alpha: 0.35,
          ),
      leading: CircleAvatar(
        backgroundColor: errorColor,
        foregroundColor: Colors.white,
        child: Text(
          summary.fullName.isNotEmpty
              ? summary.fullName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(
        summary.fullName,
        style: TextStyle(
          color: errorColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        l10n.cellAttendanceReportMemberStats(
          summary.presentCount,
          summary.consecutiveAbsenceStreak,
          summary.rollCallCount,
        ),
        style: TextStyle(color: errorColor.withValues(alpha: 0.85)),
      ),
      trailing: Icon(
        Icons.warning_amber_rounded,
        color: errorColor,
      ),
    );
  }
}
