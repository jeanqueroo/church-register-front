import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../members/services/member_service.dart';
import '../models/cell_member_attendance_summary.dart';
import '../models/leader_absence_list_item.dart';
import '../models/leader_cell_absence_report.dart';
import '../services/cell_absence_by_leader_service.dart';

class CellAbsenceByLeaderScreen extends StatefulWidget {
  const CellAbsenceByLeaderScreen({
    super.key,
    required this.churchId,
    this.registeredBy = '',
    this.permissions,
    this.reportService,
    this.memberService,
  });

  final String? churchId;
  final String registeredBy;
  final AppPermissions? permissions;
  final CellAbsenceByLeaderService? reportService;
  final MemberService? memberService;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<CellAbsenceByLeaderScreen> createState() =>
      _CellAbsenceByLeaderScreenState();
}

class _CellAbsenceByLeaderScreenState extends State<CellAbsenceByLeaderScreen> {
  late final CellAbsenceByLeaderService _reportService;
  late final MemberService _memberService;

  List<LeaderAbsenceListItem> _leaders = [];
  String? _selectedLeaderId;
  bool _loadingLeaders = true;
  bool _loadingAbsences = false;
  bool _openingMember = false;
  String? _loadError;
  String? _absencesError;

  /// Cache por líder para no volver a consultar al cambiar de selección.
  final Map<String, _LeaderAbsenceDetail> _detailByLeaderId = {};

  @override
  void initState() {
    super.initState();
    _reportService = widget.reportService ?? CellAbsenceByLeaderService();
    _memberService = widget.memberService ?? MemberService();
    _loadLeaders();
  }

  Future<void> _openMemberDetail(
    CellMemberAttendanceSummary summary,
  ) async {
    final memberId = summary.memberId.trim();
    if (memberId.isEmpty || _openingMember) return;

    setState(() => _openingMember = true);
    try {
      final member = await _memberService.fetchMemberById(memberId);
      if (!mounted) return;
      if (member == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notificationsMemberUnavailable)),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MemberDetailScreen(
            member: member,
            registeredBy: widget.registeredBy,
            memberService: _memberService,
            permissions: widget._permissions,
            leaderId: _selectedLeaderId,
            readOnly: true,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingMember = false);
    }
  }

  Future<void> _loadLeaders() async {
    final churchId = widget.churchId?.trim();
    if (churchId == null || churchId.isEmpty) {
      setState(() {
        _leaders = [];
        _selectedLeaderId = null;
        _detailByLeaderId.clear();
        _loadingLeaders = false;
      });
      return;
    }

    setState(() {
      _loadingLeaders = true;
      _loadError = null;
    });

    try {
      final leaders = await _reportService.loadLeadersForChurch(churchId);
      if (!mounted) return;
      final stillValid = leaders.any((l) => l.leaderId == _selectedLeaderId);
      setState(() {
        _leaders = leaders;
        _detailByLeaderId.removeWhere(
          (id, _) => leaders.every((l) => l.leaderId != id),
        );
        if (!stillValid) _selectedLeaderId = null;
        _loadingLeaders = false;
      });
      if (stillValid && _selectedLeaderId != null) {
        await _loadAbsencesForLeader(_selectedLeaderId!, force: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = context.l10n.cellAbsenceByLeaderLoadError;
        _loadingLeaders = false;
      });
    }
  }

  Future<void> _onLeaderSelected(String? leaderId) async {
    setState(() {
      _selectedLeaderId = leaderId;
      _absencesError = null;
    });
    if (leaderId == null || leaderId.isEmpty) return;
    if (_detailByLeaderId.containsKey(leaderId)) return;
    await _loadAbsencesForLeader(leaderId);
  }

  Future<void> _loadAbsencesForLeader(
    String leaderId, {
    bool force = false,
  }) async {
    LeaderAbsenceListItem? matched;
    for (final item in _leaders) {
      if (item.leaderId == leaderId) {
        matched = item;
        break;
      }
    }
    final leader = matched;
    if (leader == null) return;
    if (!force && _detailByLeaderId.containsKey(leaderId)) return;

    setState(() {
      _loadingAbsences = true;
      _absencesError = null;
    });

    try {
      final reports = await _reportService.loadReportsForLeader(
        leaderId: leader.leaderId,
        cells: leader.cells,
      );
      if (!mounted) return;
      setState(() {
        _detailByLeaderId[leaderId] = _LeaderAbsenceDetail.fromReports(
          leader: leader,
          reports: reports,
        );
        _loadingAbsences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _absencesError = context.l10n.cellAbsenceByLeaderLoadError;
        _loadingAbsences = false;
      });
    }
  }

  LeaderAbsenceListItem? get _selectedLeader {
    final id = _selectedLeaderId;
    if (id == null) return null;
    for (final leader in _leaders) {
      if (leader.leaderId == id) return leader;
    }
    return null;
  }

  _LeaderAbsenceDetail? get _selectedDetail {
    final id = _selectedLeaderId;
    if (id == null) return null;
    return _detailByLeaderId[id];
  }

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
    if (_loadingLeaders) {
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
                onPressed: _loadLeaders,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_leaders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLeaders,
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

    final selected = _selectedLeader;
    final detail = _selectedDetail;

    return RefreshIndicator(
      onRefresh: () async {
        final selectedId = _selectedLeaderId;
        _detailByLeaderId.clear();
        await _loadLeaders();
        if (selectedId != null) {
          await _loadAbsencesForLeader(selectedId, force: true);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedLeaderId ?? 'leader-none'),
            initialValue: _selectedLeaderId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.cellAbsenceByLeaderSelectLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_search_outlined),
            ),
            hint: Text(l10n.cellAbsenceByLeaderSelectHint),
            items: _leaders
                .map(
                  (leader) => DropdownMenuItem<String>(
                    value: leader.leaderId,
                    child: Text(
                      leader.leaderName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _onLeaderSelected,
          ),
          const SizedBox(height: 16),
          if (selected == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                l10n.cellAbsenceByLeaderNoSelection,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else if (_loadingAbsences && detail == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_absencesError != null && detail == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    _absencesError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _loadAbsencesForLeader(
                      selected.leaderId,
                      force: true,
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          else if (detail != null) ...[
            if (_loadingAbsences)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            _SelectedLeaderHeader(l10n: l10n, detail: detail),
            const SizedBox(height: 12),
            if (detail.criticalDisciples.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.cellAbsenceByLeaderLeaderOk,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...detail.criticalDisciples.map(
                (entry) => _CriticalDiscipleTile(
                  l10n: l10n,
                  summary: entry.summary,
                  cellCode: entry.cellCode,
                  enabled: !_openingMember,
                  onTap: () => _openMemberDetail(entry.summary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CriticalDiscipleEntry {
  const _CriticalDiscipleEntry({
    required this.summary,
    required this.cellCode,
  });

  final CellMemberAttendanceSummary summary;
  final String cellCode;
}

class _LeaderAbsenceDetail {
  const _LeaderAbsenceDetail({
    required this.leaderId,
    required this.leaderName,
    required this.cellCodes,
    required this.criticalDisciples,
  });

  final String leaderId;
  final String leaderName;
  final List<String> cellCodes;
  final List<_CriticalDiscipleEntry> criticalDisciples;

  int get criticalCount => criticalDisciples.length;

  factory _LeaderAbsenceDetail.fromReports({
    required LeaderAbsenceListItem leader,
    required List<LeaderCellAbsenceReport> reports,
  }) {
    final entries = <_CriticalDiscipleEntry>[];
    final codes = <String>{};

    for (final report in reports) {
      final code = report.cellCode.trim();
      if (code.isNotEmpty) codes.add(code);
      for (final summary in report.criticalDisciples) {
        entries.add(
          _CriticalDiscipleEntry(summary: summary, cellCode: report.cellCode),
        );
      }
    }

    entries.sort((a, b) {
      final byStreak = b.summary.consecutiveAbsenceStreak.compareTo(
        a.summary.consecutiveAbsenceStreak,
      );
      if (byStreak != 0) return byStreak;
      return a.summary.fullName.compareTo(b.summary.fullName);
    });

    final sortedCodes = codes.toList()..sort();
    return _LeaderAbsenceDetail(
      leaderId: leader.leaderId,
      leaderName: leader.leaderName,
      cellCodes: sortedCodes,
      criticalDisciples: List.unmodifiable(entries),
    );
  }
}

class _SelectedLeaderHeader extends StatelessWidget {
  const _SelectedLeaderHeader({
    required this.l10n,
    required this.detail,
  });

  final AppLocalizations l10n;
  final _LeaderAbsenceDetail detail;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final hasCritical = detail.criticalCount > 0;
    final cellsLabel = detail.cellCodes
        .map(l10n.cellAbsenceByLeaderCellLabel)
        .join(' · ');

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  hasCritical ? errorColor : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: Text(
                detail.leaderName.isNotEmpty
                    ? detail.leaderName[0].toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.leaderName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (cellsLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      cellsLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    l10n.cellAbsenceByLeaderCriticalCount(detail.criticalCount),
                    style: TextStyle(
                      color: hasCritical ? errorColor : null,
                      fontWeight: hasCritical ? FontWeight.w600 : null,
                    ),
                  ),
                ],
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
    required this.cellCode,
    required this.onTap,
    this.enabled = true,
  });

  final AppLocalizations l10n;
  final CellMemberAttendanceSummary summary;
  final String cellCode;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: enabled,
        onTap: enabled ? onTap : null,
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
          [
            l10n.cellAbsenceByLeaderCellLabel(cellCode),
            l10n.cellAttendanceReportMemberStats(
              summary.presentCount,
              summary.consecutiveAbsenceStreak,
              summary.rollCallCount,
            ),
          ].join(' · '),
          style: TextStyle(color: errorColor.withValues(alpha: 0.85)),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: errorColor,
        ),
      ),
    );
  }
}
