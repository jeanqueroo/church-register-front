import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/app_user_role.dart';
import '../../members/models/church_member.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../members/services/member_service.dart';
import '../../members/widgets/members_map_view.dart';
import '../models/church_leader.dart';
import '../utils/leader_members_filter.dart';

class LeaderAssignedMembersScreen extends StatefulWidget {
  const LeaderAssignedMembersScreen({
    super.key,
    required this.leader,
    required this.registeredBy,
    this.memberService,
    this.permissions,
  });

  final ChurchLeader leader;
  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions? permissions;

  @override
  State<LeaderAssignedMembersScreen> createState() =>
      _LeaderAssignedMembersScreenState();
}

class _LeaderAssignedMembersScreenState
    extends State<LeaderAssignedMembersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  MemberService get _service => widget.memberService ?? MemberService();

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _openMemberDetail(BuildContext context, ChurchMember member) {
    final viewPermissions = widget.permissions ??
        AppPermissions.fromRoles([AppUserRole.leader]);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          member: member,
          registeredBy: widget.registeredBy,
          memberService: _service,
          permissions: viewPermissions,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final cellLabel =
        widget.leader.cellCode != null ? ' · Célula ${widget.leader.cellCode}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  widget.leader.lastName.isNotEmpty
                      ? widget.leader.lastName[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.leader.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '$count integrante${count == 1 ? '' : 's'} asignado'
                      '${count == 1 ? '' : 's'}$cellLabel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin integrantes asignados',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Los integrantes con visita activada y dirección '
              'aparecerán aquí al registrarse.',
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

  Widget _buildListTab(BuildContext context, List<ChurchMember> assigned) {
    if (assigned.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: assigned.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = assigned[index];
        final parts = <String>[
          member.phone,
          if (member.wantsVisit) 'Solicita visita',
          'Registro: ${_formatDate(member.registeredAt)}',
          if (member.assignedDistanceKm != null)
            '${member.assignedDistanceKm!.toStringAsFixed(1)} km',
          if (member.geoLocation == null) 'Sin ubicación en mapa',
        ];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                member.fullName.isNotEmpty
                    ? member.fullName[0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text(member.fullName),
            subtitle: Text(parts.join(' · ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openMemberDetail(context, member),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrantes asignados'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_outlined), text: 'Lista'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
          ],
        ),
      ),
      body: StreamBuilder<List<ChurchMember>>(
        stream: _service.watchMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar los integrantes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }

          final assigned = membersAssignedToLeader(
            widget.leader,
            snapshot.data ?? [],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, assigned.length),
              Expanded(
                child: assigned.isEmpty
                    ? _buildEmptyState(context)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListTab(context, assigned),
                          MembersMapView(
                            members: assigned,
                            leader: widget.leader,
                            onMemberTap: (m) => _openMemberDetail(context, m),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
