import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/leader_gender.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../cells/services/cell_service.dart';
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
  final _scrollController = ScrollController();
  final _excelExportService = LeadersExcelExportService();
  final _cellService = CellService();
  late final TabController _tabController;

  bool _exporting = false;
  bool _hideBlocked = false;
  bool _actionInProgress = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _loadingMap = false;
  bool _hasMore = true;
  int _blockedCount = 0;
  Object? _loadError;
  List<ChurchLeader> _leaders = [];
  List<ChurchLeader>? _mapLeaders;
  String? _mapCacheKey;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  Timer? _searchDebounce;
  String _activeSearchQuery = '';

  LeaderService get _service => widget.leaderService ?? LeaderService();

  String? get _churchId {
    final id = widget.permissions.churchId?.trim();
    return id != null && id.isNotEmpty ? id : null;
  }

  String get _filterCacheKey =>
      '$_churchId|$_activeSearchQuery|$_hideBlocked';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
    _loadBlockedCount();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      _loadAllForMap();
    }
  }

  void _onScroll() {
    if (_tabController.index != 0) return;
    if (!_hasMore || _loading || _loadingMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadNextPage();
    }
  }

  Future<void> _loadBlockedCount() async {
    try {
      final count = await _service.fetchBlockedLeadersCount(churchId: _churchId);
      if (!mounted) return;
      setState(() => _blockedCount = count);
    } catch (_) {
      // El chip de bloqueados es opcional; no bloquea la lista.
    }
  }

  void _invalidateMapCache() {
    _mapLeaders = null;
    _mapCacheKey = null;
  }

  Future<void> _loadFirstPage({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _loadError = null;
      _leaders = [];
      _lastDocument = null;
      _hasMore = true;
      if (forceRefresh) {
        _invalidateMapCache();
      }
    });

    try {
      final page = await _service.fetchLeadersPage(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        hideBlocked: _hideBlocked,
      );
      if (!mounted) return;
      setState(() {
        _leaders = page.leaders;
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _loading = false;
      });
      if (_tabController.index == 1) {
        _loadAllForMap(forceRefresh: true);
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
        _leaders = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LeaderService.messageFromFirestoreException(error, context.l10n),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
        _leaders = [];
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_activeSearchQuery.isNotEmpty) return;
    if (!_hasMore || _loadingMore || _lastDocument == null) return;

    setState(() => _loadingMore = true);
    try {
      final page = await _service.fetchLeadersPage(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        startAfter: _lastDocument,
        hideBlocked: _hideBlocked,
      );
      if (!mounted) return;
      setState(() {
        _leaders = [..._leaders, ...page.leaders];
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadAllForMap({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _mapCacheKey == _filterCacheKey &&
        _mapLeaders != null) {
      return;
    }

    setState(() => _loadingMap = true);
    try {
      final leaders = await _service.fetchAllLeadersForExport(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        hideBlocked: _hideBlocked,
      );
      if (!mounted) return;
      setState(() {
        _mapLeaders = leaders;
        _mapCacheKey = _filterCacheKey;
        _loadingMap = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMap = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      if (query == _activeSearchQuery) return;
      _activeSearchQuery = query;
      _lastDocument = null;
      _hasMore = true;
      _invalidateMapCache();
      _loadFirstPage();
    });
  }

  void _onHideBlockedChanged(bool value) {
    setState(() => _hideBlocked = value);
    _lastDocument = null;
    _hasMore = true;
    _invalidateMapCache();
    _loadFirstPage(forceRefresh: true);
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
    if (!mounted) return;
    await _loadFirstPage(forceRefresh: true);
    await _loadBlockedCount();
  }

  Future<void> _exportToExcel() async {
    if (_exporting || !widget.permissions.canExportExcel) return;

    setState(() => _exporting = true);
    try {
      final leaders = await _service.fetchAllLeadersForExport(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        hideBlocked: _hideBlocked,
      );
      if (!mounted) return;
      if (leaders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.commonNoMatches)),
        );
        return;
      }
      final cellCodeByLeaderId = await _cellService.fetchCellCodeByLeaderId(
        churchId: _churchId,
      );
      if (!mounted) return;
      await _excelExportService.shareLeaders(
        leaders,
        cellCodeByLeaderId: cellCodeByLeaderId,
      );
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
      await _service.setLeaderBlocked(
        id: id,
        blocked: block,
        authUserId: leader.authUserId,
        updatedBy: widget.registeredBy,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(block ? l10n.leadersBlocked : l10n.leadersUnblocked),
        ),
      );
      await _loadFirstPage(forceRefresh: true);
      await _loadBlockedCount();
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LeaderService.messageFromFirestoreException(e, context.l10n),
          ),
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
      onChanged: _onSearchChanged,
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

  Widget _buildLeaderTile(
    BuildContext context,
    AppLocalizations l10n,
    ChurchLeader leader,
  ) {
    final parts = <String>[
      if (leader.churchOffice != null)
        leader.churchOffice!.localizedLabel(l10n),
      if (leader.cellCode != null) l10n.leadersListCellPrefix(leader.cellCode!),
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
  }

  Widget _buildListFooter(AppLocalizations l10n) {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasMore && _leaders.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            l10n.leadersListEndOfList,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return const SizedBox(height: 88);
  }

  Widget _buildListTab(BuildContext context, AppLocalizations l10n) {
    if (_leaders.isEmpty) {
      return Center(
        child: Text(
          _activeSearchQuery.isEmpty && _hideBlocked && _blockedCount > 0
              ? l10n.leadersAllBlocked
              : l10n.commonNoMatches,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      itemCount: _leaders.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= _leaders.length) {
          return _buildListFooter(l10n);
        }
        return _buildLeaderTile(context, l10n, _leaders[index]);
      },
    );
  }

  Widget _buildMapTab(BuildContext context) {
    if (_loadingMap && (_mapLeaders == null || _mapLeaders!.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    final leaders = _mapLeaders ?? _leaders;
    return Stack(
      children: [
        LeadersMapView(
          leaders: leaders,
          onLeaderTap: (leader) => _openLeaderDetail(context, leader),
        ),
        if (_loadingMap)
          const Positioned(
            top: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool get _showTabs =>
      !_loading && _loadError == null && (_leaders.isNotEmpty || _blockedCount > 0);

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading && _leaders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _leaders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.leadersListLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _loadFirstPage(forceRefresh: true),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_leaders.isEmpty && _blockedCount == 0 && _activeSearchQuery.isEmpty) {
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
                onSelected: _actionInProgress ? null : _onHideBlockedChanged,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _showTabs
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        await _loadFirstPage(forceRefresh: true);
                        await _loadBlockedCount();
                      },
                      child: _buildListTab(context, l10n),
                    ),
                    _buildMapTab(context),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadFirstPage(forceRefresh: true);
                    await _loadBlockedCount();
                  },
                  child: _buildListTab(context, l10n),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leadersListTitle),
        actions: [
          if (!_loading && widget.permissions.canExportExcel)
            IconButton(
              tooltip: l10n.membersListExportExcel,
              onPressed: _exporting ? null : _exportToExcel,
              icon: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
            ),
        ],
        bottom: _showTabs
            ? TabBar(
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
              )
            : null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: widget.permissions.canRegisterLeader
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => RegisterLeaderScreen(
                      registeredBy: widget.registeredBy,
                      churchId: widget.permissions.churchId,
                      leaderService: _service,
                      permissions: widget.permissions,
                    ),
                  ),
                );
                if (created == true && mounted) {
                  await _loadFirstPage(forceRefresh: true);
                  await _loadBlockedCount();
                }
              },
              icon: const Icon(Icons.person_add),
              label: Text(l10n.commonNew),
            )
          : null,
      body: _buildBody(context, l10n),
    );
  }
}
