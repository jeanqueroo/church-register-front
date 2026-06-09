import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/leader_gender.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../models/church_leader.dart';
import '../services/leader_service.dart';
import '../services/leaders_excel_export_service.dart';
import '../widgets/leaders_map_view.dart';
import 'leader_assigned_members_screen.dart';
import 'leader_detail_screen.dart';
import 'register_leader_screen.dart';

class LeadersListScreen extends StatelessWidget {
  const LeadersListScreen({
    super.key,
    required this.registeredBy,
    this.leaderService,
    this.permissions,
  });

  final String registeredBy;
  final LeaderService? leaderService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canViewLeadersList,
      child: _LeadersListBody(
        registeredBy: registeredBy,
        leaderService: leaderService,
        permissions: _permissions,
      ),
    );
  }
}

class _LeadersListBody extends StatefulWidget {
  const _LeadersListBody({
    required this.registeredBy,
    this.leaderService,
    required this.permissions,
  });

  final String registeredBy;
  final LeaderService? leaderService;
  final AppPermissions permissions;

  @override
  State<_LeadersListBody> createState() => _LeadersListBodyState();
}

class _LeadersListBodyState extends State<_LeadersListBody>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _excelExportService = LeadersExcelExportService();
  late final TabController _tabController;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(ChurchLeader leader, String query, AppLocalizations l10n) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      leader.lastName,
      leader.firstName,
      leader.fullName,
      leader.cellCode,
      leader.mobilePhone,
      leader.email,
      leader.churchOffice?.localizedLabel(l10n),
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  void _openAssignedMembers(BuildContext context, ChurchLeader leader) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderAssignedMembersScreen(
          leader: leader,
          registeredBy: widget.registeredBy,
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, ChurchLeader leader) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterLeaderScreen(
          registeredBy: widget.registeredBy,
          churchId: widget.permissions.churchId,
          leaderService: widget.leaderService,
          leaderToEdit: leader,
          permissions: widget.permissions,
        ),
      ),
    );
  }

  Future<void> _exportToExcel(List<ChurchLeader> leaders) async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      await _excelExportService.shareLeaders(leaders);
    } on LeadersExcelExportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonExportError)),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, ChurchLeader leader) async {
    final l10n = context.l10n;
    final id = leader.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leadersListDeleteTitle),
        content: Text(l10n.commonDeleteConfirm(leader.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await (widget.leaderService ?? LeaderService()).deleteLeader(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.leadersListDeleted)),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LeaderService.messageFromFirestoreException(e, context.l10n)),
        ),
      );
    }
  }

  void _openLeaderDetail(BuildContext context, ChurchLeader leader) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderDetailScreen(
          leader: leader,
          registeredBy: widget.registeredBy,
          leaderService: widget.leaderService,
          permissions: widget.permissions,
        ),
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: l10n.leadersListSearchHint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Color? _avatarColor(LeaderGender? gender) {
    switch (gender) {
      case LeaderGender.hombre:
        return Colors.blue.shade100;
      case LeaderGender.mujer:
        return Colors.pink.shade100;
      case null:
        return null;
    }
  }

  Widget _buildListTab(
    BuildContext context,
    List<ChurchLeader> filtered,
    LeaderService service,
    AppLocalizations l10n,
  ) {
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.commonNoMatches,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final leader = filtered[index];
        final parts = <String>[
          if (leader.churchOffice != null)
            leader.churchOffice!.localizedLabel(l10n),
          if (leader.cellCode != null)
            l10n.leadersListCellPrefix(leader.cellCode!),
          leader.mobilePhone,
          if (leader.email != null) leader.email!,
        ];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _avatarColor(leader.gender),
              child: Text(
                leader.lastName.isNotEmpty
                    ? leader.lastName[0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text('${leader.lastName}, ${leader.firstName}'),
            subtitle: Text(parts.join(' · ')),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _openLeaderDetail(context, leader);
                  case 'members':
                    _openAssignedMembers(context, leader);
                  case 'edit':
                    _openEdit(context, leader);
                  case 'delete':
                    _confirmDelete(context, leader);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'view',
                  child: Text(l10n.leadersListViewLeader),
                ),
                PopupMenuItem(
                  value: 'members',
                  child: Text(l10n.leadersListViewMembers),
                ),
                if (widget.permissions.canManageAll) ...[
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l10n.commonEdit),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      l10n.commonDelete,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () => _openLeaderDetail(context, leader),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = widget.leaderService ?? LeaderService();

    return StreamBuilder<List<ChurchLeader>>(
      stream: service.watchLeaders(churchId: widget.permissions.churchId),
      builder: (context, snapshot) {
        final leaders = snapshot.data ?? [];
        final filtered = leaders
            .where((l) => _matchesSearch(l, _searchController.text, l10n))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.leadersListTitle),
            actions: [
              if (snapshot.hasData && leaders.isNotEmpty)
                IconButton(
                  tooltip: l10n.membersListExportExcel,
                  onPressed: _exporting || filtered.isEmpty
                      ? null
                      : () => _exportToExcel(filtered),
                  icon: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                ),
            ],
            bottom: leaders.isEmpty
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
          floatingActionButton: widget.permissions.canRegisterLeader
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RegisterLeaderScreen(
                          registeredBy: widget.registeredBy,
                          churchId: widget.permissions.churchId,
                          leaderService: service,
                          permissions: widget.permissions,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.commonNew),
                )
              : null,
          body: Builder(
            builder: (context) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.leadersListLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }

          if (leaders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.supervisor_account_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.leadersListEmpty,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildSearchField(l10n),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListTab(context, filtered, service, l10n),
                    LeadersMapView(
                      leaders: filtered,
                      onLeaderTap: (leader) =>
                          _openLeaderDetail(context, leader),
                    ),
                  ],
                ),
              ),
            ],
          );
            },
          ),
        );
      },
    );
  }
}
