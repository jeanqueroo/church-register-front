import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
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

class _MembersByLeaderBody extends StatelessWidget {
  const _MembersByLeaderBody({
    required this.registeredBy,
    this.memberService,
    required this.permissions,
  });

  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions permissions;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = memberService ?? MemberService();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.membersByLeaderTitle),
      ),
      body: StreamBuilder<List<ChurchMember>>(
        stream: service.watchMembers(churchId: permissions.churchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.commonLoadListError,
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
                      l10n.membersByLeaderEmpty,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final groups = groupMembersByLeader(members);
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                            l10n.membersByLeaderAssignedCount(
                              assignedCount,
                              members.length,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _LeaderGroupTile(
                      group: group,
                      l10n: l10n,
                      formatDate: _formatDate,
                      onMemberTap: (member) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MemberDetailScreen(
                              member: member,
                              registeredBy: registeredBy,
                              memberService: service,
                              permissions: permissions,
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
    required this.l10n,
    required this.formatDate,
    required this.onMemberTap,
  });

  final LeaderMemberGroup group;
  final AppLocalizations l10n;
  final String Function(DateTime) formatDate;
  final void Function(ChurchMember member) onMemberTap;

  @override
  State<_LeaderGroupTile> createState() => _LeaderGroupTileState();
}

class _LeaderGroupTileState extends State<_LeaderGroupTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final group = widget.group;
    final subtitleParts = <String>[
      l10n.membersByLeaderMemberCount(group.count),
      if (group.cellCode != null) l10n.leaderCellLabel(group.cellCode!),
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
              group.localizedDisplayName(l10n),
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
                if (member.wantsVisit) l10n.membersMapRequestsVisit,
                l10n.membersByLeaderRegistrationDate(
                  widget.formatDate(member.registeredAt),
                ),
                if (member.locality != null) member.locality!,
                if (member.assignedDistanceKm != null)
                  l10n.memberDetailDistanceKm(
                    member.assignedDistanceKm!.toStringAsFixed(1),
                  ),
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
