import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../church/models/church_record.dart';
import '../../church/services/church_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../leaders/services/leader_service.dart';
import '../../members/models/member_visit.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../members/services/member_service.dart';
import '../../supervisors/services/supervisor_assignment_service.dart';
import '../models/follow_up_person.dart';
import '../models/visit_chart_point.dart';
import '../models/visit_dashboard_filter.dart';
import '../services/pastoral_dashboard_service.dart';
import '../widgets/dashboard_church_filter.dart';
import '../widgets/prayer_percentage_card.dart';
import '../widgets/visit_count_bar_chart.dart';

class PastoralDashboardScreen extends StatefulWidget {
  const PastoralDashboardScreen({
    super.key,
    required this.session,
    this.dashboardService,
    this.churchService,
    this.leaderService,
    this.memberService,
    this.assignmentService,
  });

  final UserSession session;
  final PastoralDashboardService? dashboardService;
  final ChurchService? churchService;
  final LeaderService? leaderService;
  final MemberService? memberService;
  final SupervisorAssignmentService? assignmentService;

  @override
  State<PastoralDashboardScreen> createState() =>
      _PastoralDashboardScreenState();
}

class _PastoralDashboardScreenState extends State<PastoralDashboardScreen> {
  static const _newMemberChartMonthCount = 6;

  late final PastoralDashboardService _dashboardService;
  late final ChurchService _churchService;
  late final LeaderService _leaderService;
  late final MemberService _memberService;
  late final SupervisorAssignmentService _assignmentService;

  VisitChartPeriod _period = VisitChartPeriod.month;
  String? _selectedChurchId;
  List<ChurchRecord> _churches = [];
  VisitDashboardFilter? _filter;
  List<VisitChartPoint> _newMemberPoints = [];
  List<FollowUpPerson> _followUpPeople = [];
  PrayerVisitStats _prayerStats = const PrayerVisitStats(
    totalVisits: 0,
    prayerVisits: 0,
  );
  int _newMembersCount = 0;
  bool _loading = true;
  bool _followUpLoading = false;
  int _followUpRequestId = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboardService =
        widget.dashboardService ?? PastoralDashboardService();
    _churchService = widget.churchService ?? ChurchService();
    _leaderService = widget.leaderService ?? LeaderService();
    _memberService = widget.memberService ?? MemberService();
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
        _error = PastoralDashboardService.messageFromException(e, context.l10n);
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
      _followUpLoading = true;
      _followUpPeople = [];
      _error = null;
    });

    if (filter.leaderIds != null && filter.leaderIds!.isEmpty) {
      _followUpRequestId++;
      setState(() {
        _newMemberPoints = [];
        _followUpPeople = [];
        _prayerStats = const PrayerVisitStats(totalVisits: 0, prayerVisits: 0);
        _newMembersCount = 0;
        _loading = false;
        _followUpLoading = false;
      });
      return;
    }

    try {
      final now = DateTime.now();
      final rangeStart = _dashboardService.rangeStartFor(_period, now);
      final rangeEnd = _dashboardService.rangeEndFor(_period, now);
      final newMemberRangeStart = _period == VisitChartPeriod.month
          ? _dashboardService.rangeStartForMonthCount(
              _newMemberChartMonthCount,
              now,
            )
          : rangeStart;

      final visitsFuture = _dashboardService.fetchVisits(
        filter: filter,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      final membersFuture = _dashboardService.fetchNewMembers(
        filter: filter,
        rangeStart: newMemberRangeStart,
        rangeEnd: rangeEnd,
      );

      final visits = await visitsFuture;
      _loadFollowUpPeopleFromVisits(visits);

      final members = await membersFuture;

      final newMemberPoints = _dashboardService.buildNewMemberChartPoints(
        members: members,
        period: _period,
        rangeStart: newMemberRangeStart,
        rangeEnd: rangeEnd,
      );
      final prayerStats = _dashboardService.prayerVisitStats(visits);

      if (!mounted) return;
      setState(() {
        _newMemberPoints = newMemberPoints;
        _prayerStats = prayerStats;
        _newMembersCount = members.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _followUpRequestId++;
      setState(() {
        _loading = false;
        _followUpLoading = false;
        _error = PastoralDashboardService.messageFromException(e, context.l10n);
      });
    }
  }

  Future<void> _loadFollowUpPeopleFromVisits(List<MemberVisit> visits) async {
    final requestId = ++_followUpRequestId;

    try {
      final people = await _dashboardService.loadFollowUpPersonsFromVisits(
        visits: visits,
        fetchMember: _memberService.fetchMemberById,
        fetchLeaderName: _fetchLeaderName,
      );
      if (!mounted || requestId != _followUpRequestId) return;
      setState(() {
        _followUpPeople = people;
        _followUpLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _followUpRequestId) return;
      setState(() {
        _followUpPeople = [];
        _followUpLoading = false;
      });
    }
  }

  Future<String?> _fetchLeaderName(String leaderId) async {
    try {
      final leader = await _leaderService.fetchLeaderById(leaderId);
      return leader?.fullName;
    } catch (_) {
      return null;
    }
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

  Future<void> _openMember(FollowUpPerson person) async {
    final member = await _memberService.fetchMemberById(person.memberId);
    if (!mounted) return;
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.dashboardMemberNotFound)),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          member: member,
          registeredBy: widget.session.email,
          permissions: widget.session.permissions,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  Widget _buildFollowUpSection() {
    final l10n = context.l10n;
    final hasPeople = _followUpPeople.isNotEmpty;
    final subtitle = _followUpLoading
        ? l10n.dashboardFollowUpSubtitle
        : hasPeople
            ? l10n.dashboardFollowUpCount(_followUpPeople.length)
            : l10n.dashboardFollowUpEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(
            l10n.dashboardFollowUpTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          children: [
            if (_followUpLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_followUpPeople.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  l10n.dashboardFollowUpEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              for (var i = 0; i < _followUpPeople.length; i++)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.bubbleOutgoing,
                        child: Icon(
                          Icons.flag_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(_followUpPeople[i].memberName),
                      subtitle: Text(
                        [
                          l10n.dashboardVisitOnDate(
                            _formatDate(_followUpPeople[i].visitDate),
                          ),
                          if (_followUpPeople[i].leaderName != null)
                            l10n.dashboardLeaderPrefix(
                              _followUpPeople[i].leaderName!,
                            ),
                        ].join('\n'),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openMember(_followUpPeople[i]),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.session.permissions;
    final l10n = context.l10n;

    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewPastoralDashboard,
      deniedMessage: l10n.dashboardPastoralDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dashboardPastoralTitle),
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
    if (_loading && _newMemberPoints.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _newMemberPoints.isEmpty && _followUpPeople.isEmpty) {
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
                l10n.dashboardNoAssignedLeadersPastoral,
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
                leading: const Icon(Icons.favorite_outline),
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
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            PrayerPercentageCard(stats: _prayerStats),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.dashboardNewMembersTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    _period == VisitChartPeriod.month
                        ? '${l10n.dashboardNewMembersCount(_newMembersCount)} · ${l10n.dashboardPeriodLast6Months}'
                        : l10n.dashboardNewMembersCount(_newMembersCount),
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
                      points: _newMemberPoints,
                      period: _period,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFollowUpSection(),
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
