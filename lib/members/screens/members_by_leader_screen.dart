import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _loadingStats = true;
  bool _searching = false;
  bool _hasMore = true;
  Object? _loadError;
  int? _totalCount;
  int? _assignedCount;
  List<ChurchMember> _members = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  Timer? _searchDebounce;
  String _activeSearchQuery = '';
  int _listRequestId = 0;

  MemberService get _service => widget.memberService ?? MemberService();

  String? get _churchId {
    final id = widget.permissions.churchId?.trim();
    return id != null && id.isNotEmpty ? id : null;
  }

  List<LeaderMemberGroup> get _groups => groupMembersByLeader(_members);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStats();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore || _searching) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadNextPage();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _service.fetchMemberAssignmentStats(
        churchId: _churchId,
        newBelieversOnly: true,
      );
      if (!mounted) return;
      setState(() {
        _totalCount = stats.total;
        _assignedCount = stats.assigned;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadFirstPage({
    bool forceRefresh = false,
    bool fromSearch = false,
  }) async {
    final requestId = ++_listRequestId;
    final keepPreviousResults = fromSearch && _members.isNotEmpty;

    setState(() {
      if (fromSearch) {
        _searching = true;
        if (!keepPreviousResults) {
          _loading = true;
        }
      } else {
        _loading = true;
        if (forceRefresh || !keepPreviousResults) {
          _members = [];
        }
      }
      _loadError = null;
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final page = await _service.fetchMembersPage(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        newBelieversOnly: true,
      );
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _members = page.members;
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _loading = false;
        _searching = false;
      });
    } catch (error) {
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _loadError = error;
        _loading = false;
        _searching = false;
        if (!keepPreviousResults) {
          _members = [];
        }
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_activeSearchQuery.isNotEmpty) return;
    if (!_hasMore || _loadingMore || _lastDocument == null) return;

    setState(() => _loadingMore = true);
    try {
      final page = await _service.fetchMembersPage(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        startAfter: _lastDocument,
        newBelieversOnly: true,
      );
      if (!mounted) return;
      setState(() {
        _members = [..._members, ...page.members];
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

  Future<void> _refresh() async {
    await Future.wait([
      _loadStats(),
      _loadFirstPage(forceRefresh: true),
    ]);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      final query = value.trim();
      if (query == _activeSearchQuery) return;
      _activeSearchQuery = query;
      _loadFirstPage(fromSearch: true);
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  int get _displayTotal => _totalCount ?? _members.length;

  int get _displayAssigned {
    if (_assignedCount != null) return _assignedCount!;
    return _members
        .where(
          (m) =>
              m.assignedLeaderId != null ||
              (m.assignedLeaderName?.trim().isNotEmpty ?? false),
        )
        .length;
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return TextField(
      key: const ValueKey('members_by_leader_search'),
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: l10n.membersListSearchHint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return Padding(
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
                child: _loadingStats && _totalCount == null
                    ? const SizedBox(
                        height: 20,
                        child: LinearProgressIndicator(),
                      )
                    : Text(
                        l10n.membersByLeaderAssignedCount(
                          _displayAssigned,
                          _displayTotal,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
              ),
            ],
          ),
        ),
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
    if (!_hasMore && _members.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            l10n.membersListEndOfList,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }

  Widget _buildGroupsList(AppLocalizations l10n) {
    final groups = _groups;

    if (groups.isEmpty) {
      return Center(
        child: Text(
          _activeSearchQuery.isEmpty
              ? l10n.membersByLeaderEmpty
              : l10n.commonNoMatches,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index >= groups.length) {
          return _buildListFooter(l10n);
        }
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LeaderGroupTile(
            group: group,
            l10n: l10n,
            formatDate: _formatDate,
            onMemberTap: (member) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MemberDetailScreen(
                    member: member,
                    registeredBy: widget.registeredBy,
                    memberService: _service,
                    permissions: widget.permissions,
                  ),
                ),
              );
            },
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
        title: Text(l10n.membersByLeaderTitle),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildSearchField(l10n),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _buildSummaryCard(l10n),
        Expanded(child: _buildListContent(l10n)),
      ],
    );
  }

  Widget _buildListContent(AppLocalizations l10n) {
    if (_loading && _members.isEmpty && !_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _members.isEmpty && !_searching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.commonLoadListError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _refresh,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty && _activeSearchQuery.isEmpty && !_searching) {
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _buildGroupsList(l10n),
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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final group = widget.group;
    final subtitleParts = <String>[
      l10n.membersByLeaderMemberCount(group.count),
      if (group.cellCode != null) l10n.leaderCellLabel(group.cellCode!),
    ];

    return Card(
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
          if (_expanded) const Divider(height: 1),
          if (_expanded)
            ...group.members.map((member) {
              final parts = <String>[
                member.phone,
                if (member.assignmentKindLabel(l10n) != null)
                  member.assignmentKindLabel(l10n)!,
                if (member.isPastoralLeaderAssignment &&
                    member.wantsVisit)
                  l10n.membersMapRequestsVisit,
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
