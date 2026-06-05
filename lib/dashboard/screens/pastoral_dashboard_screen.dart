import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../church/models/church_record.dart';
import '../../church/services/church_service.dart';
import '../../core/theme/app_theme.dart';
import '../../leaders/services/leader_service.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../members/services/member_service.dart';
import '../../supervisors/services/supervisor_assignment_service.dart';
import '../models/follow_up_person.dart';
import '../models/visit_chart_point.dart';
import '../models/visit_dashboard_filter.dart';
import '../services/pastoral_dashboard_service.dart';
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
    _initialize();
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
      _filter = await _buildFilter();
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = PastoralDashboardService.messageFromException(e);
      });
    }
  }

  Future<VisitDashboardFilter> _buildFilter() async {
    final permissions = widget.session.permissions;

    if (permissions.isSuperAdmin) {
      final church = _selectedChurchId == null
          ? null
          : _churches.where((c) => c.id == _selectedChurchId).firstOrNull;
      return VisitDashboardFilter(
        churchId: _selectedChurchId,
        scopeLabel: church == null
            ? 'Todas las iglesias'
            : church.profile.name,
      );
    }

    if (permissions.isAdmin) {
      return VisitDashboardFilter(
        churchId: permissions.churchId,
        scopeLabel: 'Tu iglesia',
      );
    }

    if (permissions.isSupervisor) {
      final leaderIds = await _assignmentService.fetchSupervisedLeaderIds(
        widget.session.uid,
      );
      return VisitDashboardFilter(
        churchId: permissions.churchId,
        leaderIds: leaderIds.toSet(),
        scopeLabel: 'Tus líderes asignados',
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
        _newMemberPoints = [];
        _followUpPeople = [];
        _prayerStats = const PrayerVisitStats(totalVisits: 0, prayerVisits: 0);
        _newMembersCount = 0;
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
      final members = await _dashboardService.fetchNewMembers(
        filter: filter,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      final newMemberPoints = _dashboardService.buildNewMemberChartPoints(
        members: members,
        period: _period,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      final prayerStats = _dashboardService.prayerVisitStats(visits);
      var followUpPeople =
          _dashboardService.followUpPersonsFromVisits(visits);
      followUpPeople = await _dashboardService.enrichFollowUpPersons(
        followUpPeople,
        fetchMember: _memberService.fetchMemberById,
        fetchLeaderName: _fetchLeaderName,
      );

      if (!mounted) return;
      setState(() {
        _newMemberPoints = newMemberPoints;
        _followUpPeople = followUpPeople;
        _prayerStats = prayerStats;
        _newMembersCount = members.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = PastoralDashboardService.messageFromException(e);
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
    _filter = await _buildFilter();
    await _loadData();
  }

  Future<void> _openMember(FollowUpPerson person) async {
    final member = await _memberService.fetchMemberById(person.memberId);
    if (!mounted) return;
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el integrante.')),
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personas que requieren seguimiento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Marcadas en visitas del período',
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
          else if (_followUpPeople.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay personas con seguimiento pendiente en este período.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < _followUpPeople.length; i++) ...[
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
                        'Visita: ${_formatDate(_followUpPeople[i].visitDate)}',
                        if (_followUpPeople[i].leaderName != null)
                          'Líder: ${_followUpPeople[i].leaderName}',
                      ].join('\n'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openMember(_followUpPeople[i]),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.session.permissions;

    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewPastoralDashboard,
      deniedMessage: 'No tienes permiso para ver el dashboard pastoral.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard pastoral'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
              onPressed: _loading ? null : _loadData,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
                child: const Text('Reintentar'),
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
                'Sin líderes asignados',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cuando el administrador te asigne líderes, '
                'verás aquí el seguimiento pastoral.',
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
                title: Text(_filter!.scopeLabel!),
                subtitle: Text(_periodLabel()),
              ),
            ),
          if (widget.session.permissions.isSuperAdmin) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedChurchId,
              decoration: const InputDecoration(
                labelText: 'Iglesia',
                prefixIcon: Icon(Icons.church_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas las iglesias'),
                ),
                ..._churches.map(
                  (church) => DropdownMenuItem<String?>(
                    value: church.id,
                    child: Text(church.profile.name),
                  ),
                ),
              ],
              onChanged: _loading ? null : _onChurchChanged,
            ),
          ],
          const SizedBox(height: 16),
          SegmentedButton<VisitChartPeriod>(
            segments: VisitChartPeriod.values
                .map(
                  (period) => ButtonSegment(
                    value: period,
                    label: Text(period.label),
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
          _buildFollowUpSection(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nuevos creyentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '$_newMembersCount registrados en el período',
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
        ],
      ),
    );
  }

  String _periodLabel() {
    switch (_period) {
      case VisitChartPeriod.day:
        return 'Últimos 14 días';
      case VisitChartPeriod.month:
        return 'Últimos 12 meses';
      case VisitChartPeriod.year:
        return 'Últimos 5 años';
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
