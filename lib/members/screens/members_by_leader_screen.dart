import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/utils/list_search.dart';
import '../../core/widgets/person_list_search_field.dart';
import '../models/church_member.dart';
import '../models/leader_member_group.dart';
import '../services/member_service.dart';
import 'member_detail_screen.dart';

class MembersByLeaderScreen extends StatelessWidget {
  const MembersByLeaderScreen({
    super.key,
    required this.registeredBy,
    this.memberService,
    this.permissions,
  });

  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canViewMembersByLeader,
      child: _MembersByLeaderBody(
        registeredBy: registeredBy,
        memberService: memberService,
        permissions: _permissions,
      ),
    );
  }
}

class _MembersByLeaderBody extends StatefulWidget {
  const _MembersByLeaderBody({
    required this.registeredBy,
    this.memberService,
    required this.permissions,
  });

  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions permissions;

  @override
  State<_MembersByLeaderBody> createState() => _MembersByLeaderBodyState();
}

class _MembersByLeaderBodyState extends State<_MembersByLeaderBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.memberService ?? MemberService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevos creyentes por líder'),
      ),
      body: StreamBuilder<List<ChurchMember>>(
        stream: service.watchMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar la lista.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay nuevos creyentes registrados',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final allGroups = groupMembersByLeader(members);
          final query = _searchController.text;
          final groups = filterLeaderMemberGroups(allGroups, query);
          final assignedCount = members
              .where(
                (m) =>
                    m.assignedLeaderId != null ||
                    (m.assignedLeaderName?.trim().isNotEmpty ?? false),
              )
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.how_to_reg_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$assignedCount de ${members.length} nuevos creyentes '
                            'con líder asignado',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PersonListSearchField(
                controller: _searchController,
                hintText: 'Buscar por líder, nombre o teléfono…',
                onChanged: (_) => setState(() {}),
              ),
              Expanded(
                child: groups.isEmpty
                    ? PersonListSearchEmptyState(query: query)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return _LeaderGroupTile(
                            group: group,
                            formatDate: _formatDate,
                            onMemberTap: (member) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MemberDetailScreen(
                                    member: member,
                                    registeredBy: widget.registeredBy,
                                    memberService: service,
                                    permissions: widget.permissions,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderGroupTile extends StatefulWidget {
  const _LeaderGroupTile({
    required this.group,
    required this.formatDate,
    required this.onMemberTap,
  });

  final LeaderMemberGroup group;
  final String Function(DateTime) formatDate;
  final void Function(ChurchMember member) onMemberTap;

  @override
  State<_LeaderGroupTile> createState() => _LeaderGroupTileState();
}

class _LeaderGroupTileState extends State<_LeaderGroupTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final subtitleParts = <String>[
      '${group.count} ${group.count == 1 ? 'nuevo creyente' : 'nuevos creyentes'}',
      if (group.cellCode != null) 'Célula ${group.cellCode}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: group.isUnassigned
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                group.isUnassigned
                    ? Icons.person_off_outlined
                    : Icons.supervisor_account,
                color: group.isUnassigned
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              group.leaderName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitleParts.join(' · ')),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            const Divider(height: 1),
          if (_expanded)
            ...group.members.map((member) {
              final parts = <String>[
                member.phone,
                if (member.wantsVisit) 'Solicita visita',
                'Registro: ${widget.formatDate(member.registeredAt)}',
                if (member.locality != null) member.locality!,
                if (member.assignedDistanceKm != null)
                  '${member.assignedDistanceKm!.toStringAsFixed(1)} km',
              ];

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  child: Text(
                    member.fullName.isNotEmpty
                        ? member.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                title: Text(member.fullName),
                subtitle: Text(parts.join(' · ')),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => widget.onMemberTap(member),
              );
            }),
        ],
      ),
    );
  }
}
