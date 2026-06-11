import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../church/models/church_record.dart';
import '../../church/services/church_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../leaders/services/leader_service.dart';
import '../../supervisors/services/supervisor_assignment_service.dart';
import '../models/visit_chart_point.dart';
import '../models/visit_dashboard_filter.dart';
import '../services/visit_dashboard_service.dart';
import '../widgets/dashboard_church_filter.dart';
import '../widgets/visit_count_bar_chart.dart';
import '../widgets/visit_ranked_list.dart';

class VisitsDashboardScreen extends StatefulWidget {
  const VisitsDashboardScreen({
    super.key,
    required this.session,
    this.dashboardService,
    this.churchService,
    this.leaderService,
    this.assignmentService,
  });

  final UserSession session;
  final VisitDashboardService? dashboardService;
  final ChurchService? churchService;
  final LeaderService? leaderService;
  final SupervisorAssignmentService? assignmentService;

  @override
  State<VisitsDashboardScreen> createState() => _VisitsDashboardScreenState();
}

class _VisitsDashboardScreenState extends State<VisitsDashboardScreen> {
  late final VisitDashboardService _dashboardService;
  late final ChurchService _churchService;
  late final LeaderService _leaderService;
  late final SupervisorAssignmentService _assignmentService;

  VisitChartPeriod _period = VisitChartPeriod.month;
  String? _selectedChurchId;
  List<ChurchRecord> _churches = [];
  VisitDashboardFilter? _filter;
  List<VisitChartPoint> _chartPoints = [];
  List<VisitChartPoint> _visitPlacePoints = [];
  List<VisitChartPoint> _prayerRequestPoints = [];
  Map<String, int> _leaderCounts = {};
  Map<String, String> _leaderNames = {};
  int _totalVisits = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? VisitDashboardService();
    _churchService = widget.churchService ?? ChurchService();
    _leaderService = widget.leaderService ?? LeaderService();
    _assignmentService =
        widget.assignmentService ?? SupervisorAssignmentService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.session.permissions.isSuperAdmin) {
        _churches = await _churchService.fetchChurches();
      }
      if (!mounted) return;
      _filter = await _buildFilter(context.l10n);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = VisitDashboardService.messageFromException(e, context.l10n);
      });
    }
  }

  Future<VisitDashboardFilter> _buildFilter(AppLocalizations l10n) async {
    final permissions = widget.session.permissions;

    if (permissions.isSuperAdmin) {
      final church = _selectedChurchId == null
          ? null
          : _churches.where((c) => c.id == _selectedChurchId).firstOrNull;
      return VisitDashboardFilter(
        churchId: _selectedChurchId,
        scopeLabel: church == null
            ? l10n.dashboardScopeAllChurches
            : church.profile.name,
      );
    }

    if (permissions.isAdmin) {
      final churchId = permissions.churchId?.trim();
      if (churchId == null || churchId.isEmpty) {
        throw StateError(l10n.dashboardAdminMissingChurch);
      }
      return VisitDashboardFilter(
        churchId: churchId,
        scopeLabel: l10n.dashboardScopeYourChurch,
      );
    }

    if (permissions.isSupervisor) {
      final leaderIds = await _assignmentService.fetchSupervisedLeaderIds(
        widget.session.uid,
      );
      return VisitDashboardFilter(
        churchId: permissions.churchId,
        leaderIds: leaderIds.toSet(),
        scopeLabel: l10n.dashboardScopeYourLeaders,
      );
    }

    throw StateError('Rol sin acceso al dashboard');
  }

  Future<void> _loadData() async {
    final filter = _filter;
    if (filter == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    if (filter.leaderIds != null && filter.leaderIds!.isEmpty) {
      setState(() {
        _chartPoints = [];
        _visitPlacePoints = [];
        _prayerRequestPoints = [];
        _leaderCounts = {};
        _leaderNames = {};
        _totalVisits = 0;
        _loading = false;
      });
      return;
    }

    try {
      final now = DateTime.now();
      final rangeStart = _dashboardService.rangeStartFor(_period, now);
      final rangeEnd = _dashboardService.rangeEndFor(_period, now);

      final visits = await _dashboardService.fetchVisits(
        filter: filter,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      final points = _dashboardService.buildChartPoints(
        visits: visits,
        period: _period,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      final leaderCounts = _dashboardService.countByLeader(visits);
      final leaderNames = await _resolveLeaderNames(leaderCounts.keys);
      final visitPlacePoints = _dashboardService.countByVisitPlace(visits);
      final prayerRequestPoints =
          _dashboardService.countCommonPrayerRequests(visits);

      if (!mounted) return;
      setState(() {
        _chartPoints = points;
        _visitPlacePoints = visitPlacePoints;
        _prayerRequestPoints = prayerRequestPoints;
        _leaderCounts = leaderCounts;
        _leaderNames = leaderNames;
        _totalVisits = visits.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = VisitDashboardService.messageFromException(e, context.l10n);
      });
    }
  }

  Future<Map<String, String>> _resolveLeaderNames(
    Iterable<String> leaderIds,
  ) async {
    final names = <String, String>{};
    for (final leaderId in leaderIds) {
      try {
        final leader = await _leaderService.fetchLeaderById(leaderId);
        names[leaderId] = leader?.fullName ?? leaderId;
      } catch (_) {
        names[leaderId] = leaderId;
      }
    }
    return names;
  }

  Future<void> _onPeriodChanged(VisitChartPeriod period) async {
    setState(() => _period = period);
    await _loadData();
  }

  Future<void> _onChurchChanged(String? churchId) async {
    setState(() => _selectedChurchId = churchId);
    _filter = await _buildFilter(context.l10n);
    await _loadData();
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primaryLight),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderBreakdown() {
    if (_leaderCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final entries = _leaderCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardVisitsByLeader,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: entries.map((entry) {
                final name = _leaderNames[entry.key] ?? entry.key;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.bubbleOutgoing,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(name),
                  trailing: Chip(
                    label: Text('${entry.value}'),
                    backgroundColor: AppColors.primaryLight.withValues(
                      alpha: 0.15,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.session.permissions;
    final l10n = context.l10n;

    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewVisitsDashboard,
      deniedMessage: l10n.dashboardVisitsDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dashboardVisitsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
              onPressed: _loading ? null : _loadData,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_loading && _chartPoints.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _chartPoints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initialize,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_filter?.leaderIds != null &&
        _filter!.leaderIds!.isEmpty &&
        !_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dashboardNoAssignedLeadersTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dashboardNoAssignedLeadersVisits,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_filter?.scopeLabel != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: Text(
                  _filter!.scopeLabel!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                subtitle: Text(_periodLabel(l10n)),
              ),
            ),
          if (widget.session.permissions.isSuperAdmin) ...[
            const SizedBox(height: 12),
            DashboardChurchFilter(
              churches: _churches,
              selectedChurchId: _selectedChurchId,
              enabled: !_loading,
              allChurchesLabel: l10n.dashboardScopeAllChurches,
              churchLabel: l10n.dashboardChurchLabel,
              onChanged: _onChurchChanged,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryCard(
                title: l10n.dashboardTotalPeriod,
                value: '$_totalVisits',
                icon: Icons.event_available_outlined,
              ),
              const SizedBox(width: 12),
              _summaryCard(
                title: l10n.dashboardLeadersWithVisits,
                value: '${_leaderCounts.length}',
                icon: Icons.groups_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<VisitChartPeriod>(
            segments: VisitChartPeriod.values
                .map(
                  (period) => ButtonSegment(
                    value: period,
                    label: Text(period.localizedLabel(l10n)),
                  ),
                )
                .toList(),
            selected: {_period},
            onSelectionChanged: _loading
                ? null
                : (selection) => _onPeriodChanged(selection.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.dashboardVisitCount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    VisitCountBarChart(
                      points: _chartPoints,
                      period: _period,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.dashboardTopVisitPlaces,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    l10n.dashboardByVisitPlace,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    VisitCountBarChart(
                      points: _visitPlacePoints,
                      period: _period,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardTopPrayerRequests,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        l10n.dashboardPrayerRequestsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  VisitRankedList(
                    items: _prayerRequestPoints,
                    emptyMessage: l10n.dashboardNoPrayerRequests,
                  ),
              ],
            ),
          ),
          if (_filter?.restrictsLeaders == true || _leaderCounts.isNotEmpty)
            _buildLeaderBreakdown(),
        ],
      ),
    );
  }

  String _periodLabel(AppLocalizations l10n) {
    switch (_period) {
      case VisitChartPeriod.day:
        return l10n.dashboardPeriodLast14Days;
      case VisitChartPeriod.month:
        return l10n.dashboardPeriodLast12Months;
      case VisitChartPeriod.year:
        return l10n.dashboardPeriodLast5Years;
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
