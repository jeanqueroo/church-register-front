import 'dart:async';

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
  final _searchFocusNode = FocusNode();
  final _excelExportService = LeadersExcelExportService();
  late final TabController _tabController;
  bool _exporting = false;
  bool _hideBlocked = false;
  bool _actionInProgress = false;
  List<ChurchLeader> _leaders = [];
  bool _loading = true;
  Object? _loadError;
  StreamSubscription<List<ChurchLeader>>? _leadersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final service = widget.leaderService ?? LeaderService();
    _leadersSubscription = service
        .watchLeaders(churchId: widget.permissions.churchId)
        .listen(
          (leaders) {
            if (!mounted) return;
            setState(() {
              _leaders = leaders;
              _loading = false;
              _loadError = null;
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadError = error;
            });
          },
        );
  }

  @override
  void dispose() {
    _leadersSubscription?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  int get _blockedCount => _leaders.where((l) => l.isBlocked).length;

  List<ChurchLeader> _filteredLeaders(AppLocalizations l10n) => _leaders
      .where((l) => !_hideBlocked || !l.isBlocked)
      .where((l) => _matchesSearch(l, _searchController.text, l10n))
      .toList();

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

  Future<void> _confirmBlock(
    BuildContext context,
    ChurchLeader leader, {
    required bool block,
  }) async {
    if (!widget.permissions.canManageAll || _actionInProgress) return;

    final l10n = context.l10n;
    final id = leader.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(block ? l10n.leadersBlockTitle : l10n.leadersUnblockTitle),
        content: Text(
          block
              ? l10n.leadersBlockConfirm(leader.fullName)
              : l10n.leadersUnblockConfirm(leader.fullName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(block ? l10n.commonBlock : l10n.commonUnblock),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await (widget.leaderService ?? LeaderService()).setLeaderBlocked(
        id: id,
        blocked: block,
        authUserId: leader.authUserId,
        updatedBy: widget.registeredBy,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(block ? l10n.leadersBlocked : l10n.leadersUnblocked)),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LeaderService.messageFromFirestoreException(e, context.l10n)),
        ),
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
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
      key: const ValueKey('leaders_list_search'),
      controller: _searchController,
      focusNode: _searchFocusNode,
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
          _searchController.text.trim().isEmpty && _hideBlocked
              ? l10n.leadersAllBlocked
              : l10n.commonNoMatches,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
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

        final blocked = leader.isBlocked;

        return Card(
          color: blocked
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _avatarColor(leader.gender),
              child: Text(
                leader.lastName.isNotEmpty
                    ? leader.lastName[0].toUpperCase()
                    : '?',
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text('${leader.lastName}, ${leader.firstName}'),
                ),
                if (blocked)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: Text(l10n.commonBlocked),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(parts.join(' · ')),
            trailing: PopupMenuButton<String>(
              enabled: !_actionInProgress,
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _openLeaderDetail(context, leader);
                  case 'members':
                    _openAssignedMembers(context, leader);
                  case 'edit':
                    _openEdit(context, leader);
                  case 'block':
                    _confirmBlock(context, leader, block: true);
                  case 'unblock':
                    _confirmBlock(context, leader, block: false);
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
                    value: blocked ? 'unblock' : 'block',
                    child: Text(
                      blocked ? l10n.commonUnblock : l10n.commonBlock,
                    ),
                  ),
                ],
              ],
            ),
            onTap: _actionInProgress
                ? null
                : () => _openLeaderDetail(context, leader),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    LeaderService service,
    List<ChurchLeader> filtered,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
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

    if (_leaders.isEmpty) {
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
        if (_blockedCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(
                  _hideBlocked
                      ? l10n.leadersShowBlocked(_blockedCount)
                      : l10n.leadersHideBlocked(_blockedCount),
                ),
                selected: _hideBlocked,
                onSelected: _actionInProgress
                    ? null
                    : (v) => setState(() => _hideBlocked = v),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListTab(context, filtered, service, l10n),
              LeadersMapView(
                leaders: filtered,
                onLeaderTap: (leader) => _openLeaderDetail(context, leader),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = widget.leaderService ?? LeaderService();
    final filtered = _filteredLeaders(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leadersListTitle),
        actions: [
          if (!_loading && _leaders.isNotEmpty)
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
        bottom: _leaders.isEmpty
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
      body: _buildBody(context, l10n, service, filtered),
    );
  }
}
