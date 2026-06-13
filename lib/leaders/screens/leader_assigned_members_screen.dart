import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/app_user_role.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../members/models/church_member.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../members/screens/register_member_visit_screen.dart';
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

  String? get _churchId =>
      widget.permissions?.churchId ?? widget.leader.churchId;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _openMemberDetail(BuildContext context, ChurchMember member) {
    final viewPermissions = widget.permissions ??
        AppPermissions.fromRoles(
          [AppUserRole.leader],
          churchId: widget.leader.churchId,
        );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          member: member,
          registeredBy: widget.registeredBy,
          memberService: _service,
          permissions: viewPermissions,
          leaderId: widget.leader.id,
        ),
      ),
    );
  }

  void _openRegisterVisit(BuildContext context, ChurchMember member) {
    final leaderId = widget.leader.id;
    final memberId = member.id;
    if (leaderId == null || leaderId.isEmpty || memberId == null) return;

    final viewPermissions = widget.permissions ??
        AppPermissions.fromRoles(
          [AppUserRole.leader],
          churchId: widget.leader.churchId,
        );

    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMemberVisitScreen(
          member: member,
          leaderId: leaderId,
          registeredBy: widget.registeredBy,
          permissions: viewPermissions,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final l10n = context.l10n;
    final cellSuffix = widget.leader.cellCode != null
        ? ' ${l10n.leaderAssignedCellSuffix(widget.leader.cellCode!)}'
        : '';

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
                      '${l10n.leaderAssignedCount(count)}$cellSuffix',
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
    final l10n = context.l10n;
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
              l10n.leaderAssignedEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.leaderAssignedEmptySubtitle,
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
    final l10n = context.l10n;
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
          if (member.wantsVisit) l10n.membersMapRequestsVisit,
          l10n.membersByLeaderRegistrationDate(
            _formatDate(member.registeredAt),
          ),
          if (member.assignedDistanceKm != null)
            l10n.memberDetailDistanceKm(
              member.assignedDistanceKm!.toStringAsFixed(1),
            ),
          if (member.geoLocation == null) l10n.leaderAssignedNoMapLocation,
        ];

        final canRegisterVisit =
            (widget.permissions?.canRegisterMemberVisits ?? true) &&
            widget.leader.id != null &&
            member.isPastoralLeaderAssignment &&
            member.assignedLeaderId == widget.leader.id;

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canRegisterVisit)
                  IconButton(
                    icon: const Icon(Icons.event_note_outlined),
                    tooltip: l10n.leaderAssignedRegisterVisit,
                    onPressed: () => _openRegisterVisit(context, member),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _openMemberDetail(context, member),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderAssignedTitle),
        bottom: TabBar(
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
      body: StreamBuilder<List<ChurchMember>>(
        stream: widget.leader.id != null && widget.leader.id!.isNotEmpty
            ? _service.watchMembersAssignedToLeader(
                leaderId: widget.leader.id!,
                churchId: _churchId,
              )
            : Stream<List<ChurchMember>>.value(const []),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.leaderAssignedLoadError,
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
