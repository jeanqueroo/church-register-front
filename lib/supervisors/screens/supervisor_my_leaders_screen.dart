import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/screens/leader_assigned_members_screen.dart';
import '../../leaders/screens/leader_detail_screen.dart';
import '../../leaders/services/leader_service.dart';
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

class _SupervisorMyLeadersScreenState extends State<SupervisorMyLeadersScreen> {
  late final SupervisorAssignmentService _assignmentService;
  late final LeaderService _leaderService;
  final _searchController = TextEditingController();

  List<ChurchLeader> _leaders = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _assignmentService =
        widget.assignmentService ?? SupervisorAssignmentService();
    _leaderService = widget.leaderService ?? LeaderService();
    _loadLeaders();
  }

  @override
  void dispose() {
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
        _loadError = SupervisorAssignmentService.messageFromException(e);
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

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: widget.session.permissions,
      allowed: widget.session.permissions.canViewMySupervisedLeaders,
      deniedMessage: 'No tienes permiso para ver tus líderes asignados.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis líderes asignados'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
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
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredLeaders;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.supervisor_account_outlined),
            ),
            title: Text(
              widget.session.resolvedDisplayName.isNotEmpty
                  ? widget.session.resolvedDisplayName
                  : widget.session.email,
            ),
            subtitle: Text(
              '${_leaders.length} líder${_leaders.length == 1 ? '' : 'es'} '
              'bajo tu supervisión',
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar líder',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (_leaders.isEmpty)
          Padding(
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
                  'Sin líderes asignados',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'El administrador te asignará líderes cuando corresponda.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Ningún líder coincide con la búsqueda.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...filtered.map((leader) {
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
                        SupervisorAssignmentService.leaderLabel(leader),
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
                              label: const Text('Ver líder'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openLeaderMembers(leader),
                              icon: const Icon(Icons.people_outline),
                              label: const Text('Creyentes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
