import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/screens/leader_assigned_members_screen.dart';
import '../../leaders/screens/leader_detail_screen.dart';
import '../../leaders/services/leader_service.dart';
import '../../leaders/widgets/leaders_map_view.dart';
import '../services/supervisor_assignment_service.dart';

/// Vista de solo lectura: líderes asignados al supervisor actual.
class SupervisorMyLeadersScreen extends StatefulWidget {
  const SupervisorMyLeadersScreen({
    super.key,
    required this.session,
    this.assignmentService,
    this.leaderService,
  });

  final UserSession session;
  final SupervisorAssignmentService? assignmentService;
  final LeaderService? leaderService;

  @override
  State<SupervisorMyLeadersScreen> createState() =>
      _SupervisorMyLeadersScreenState();
}

class _SupervisorMyLeadersScreenState extends State<SupervisorMyLeadersScreen>
    with SingleTickerProviderStateMixin {
  late final SupervisorAssignmentService _assignmentService;
  late final LeaderService _leaderService;
  late final TabController _tabController;
  final _searchController = TextEditingController();

  List<ChurchLeader> _leaders = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _assignmentService =
        widget.assignmentService ?? SupervisorAssignmentService();
    _leaderService = widget.leaderService ?? LeaderService();
    _loadLeaders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaders() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final ids = await _assignmentService.fetchSupervisedLeaderIds(
        widget.session.uid,
      );
      final leaders = <ChurchLeader>[];
      for (final id in ids) {
        final leader = await _leaderService.fetchLeaderById(id);
        if (leader != null) {
          leaders.add(leader);
        }
      }
      leaders.sort((a, b) => a.fullName.compareTo(b.fullName));

      if (!mounted) return;
      setState(() {
        _leaders = leaders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = SupervisorAssignmentService.messageFromException(
          e,
          context.l10n,
        );
      });
    }
  }

  List<ChurchLeader> get _filteredLeaders {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _leaders;

    return _leaders.where((leader) {
      final haystack = [
        leader.fullName,
        leader.firstName,
        leader.lastName,
        leader.cellCode,
        leader.locality,
        leader.mobilePhone,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _openLeaderDetail(ChurchLeader leader) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderDetailScreen(
          leader: leader,
          registeredBy: widget.session.email,
          leaderService: _leaderService,
          permissions: widget.session.permissions,
        ),
      ),
    );
  }

  void _openLeaderMembers(ChurchLeader leader) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderAssignedMembersScreen(
          leader: leader,
          registeredBy: widget.session.email,
          permissions: widget.session.permissions,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.supervisor_account_outlined),
        ),
        title: Text(
          widget.session.resolvedDisplayName.isNotEmpty
              ? widget.session.resolvedDisplayName
              : widget.session.email,
        ),
        subtitle: Text(l10n.supervisorMyLeadersCount(_leaders.length)),
      ),
    );
  }

  Widget _buildSearchField() {
    final l10n = context.l10n;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: l10n.supervisorMyLeadersSearchHint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.supervisorMyLeadersEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supervisorMyLeadersEmptySubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        l10n.supervisorMyLeadersNoSearchResults,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildLeaderCard(ChurchLeader leader) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                child: Text(
                  leader.lastName.isNotEmpty
                      ? leader.lastName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(leader.fullName),
              subtitle: Text(
                SupervisorAssignmentService.leaderLabel(leader, l10n),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openLeaderDetail(leader),
                      icon: const Icon(Icons.person_outline),
                      label: Text(l10n.leadersListViewLeader),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openLeaderMembers(leader),
                      icon: const Icon(Icons.people_outline),
                      label: Text(l10n.supervisorMyLeadersViewMembers),
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

  Widget _buildListTab(List<ChurchLeader> filtered) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (filtered.isEmpty)
          _buildNoSearchResults()
        else
          ...filtered.map(_buildLeaderCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RoleGate(
      permissions: widget.session.permissions,
      allowed: widget.session.permissions.canViewMySupervisedLeaders,
      deniedMessage: l10n.supervisorMyLeadersDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.supervisorMyLeadersTitle),
          bottom: _loading || _loadError != null || _leaders.isEmpty
              ? null
              : TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.list_outlined),
                      text: l10n.leaderAssignedTabList,
                    ),
                    Tab(
                      icon: const Icon(Icons.map_outlined),
                      text: l10n.leaderAssignedTabMap,
                    ),
                  ],
                ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;

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
                onPressed: _loadLeaders,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_leaders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildEmptyState(),
        ],
      );
    }

    final filtered = _filteredLeaders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildSearchField(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListTab(filtered),
              LeadersMapView(
                leaders: filtered,
                onLeaderTap: _openLeaderDetail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
