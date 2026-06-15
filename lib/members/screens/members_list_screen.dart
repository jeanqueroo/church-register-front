import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../auth/models/app_permissions.dart';
import '../../l10n/app_localizations.dart';
import '../../auth/widgets/role_gate.dart';
import '../models/church_member.dart';
import '../services/member_service.dart';
import '../services/members_excel_export_service.dart';
import 'member_detail_screen.dart';
import 'register_member_screen.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({
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
      allowed: _permissions.canViewMembersList,
      child: _MembersListBody(
        registeredBy: registeredBy,
        memberService: memberService,
        permissions: _permissions,
      ),
    );
  }
}

class _MembersListBody extends StatefulWidget {
  const _MembersListBody({
    required this.registeredBy,
    this.memberService,
    required this.permissions,
  });

  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions permissions;

  @override
  State<_MembersListBody> createState() => _MembersListBodyState();
}

class _MembersListBodyState extends State<_MembersListBody> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _excelExportService = MembersExcelExportService();

  bool _exporting = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _loadError;
  List<ChurchMember> _members = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  Timer? _searchDebounce;
  String _activeSearchQuery = '';

  MemberService get _service => widget.memberService ?? MemberService();

  String? get _churchId {
    final id = widget.permissions.churchId?.trim();
    return id != null && id.isNotEmpty ? id : null;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    if (!_hasMore || _loading || _loadingMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _loadError = null;
      _members = [];
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final page = await _service.fetchMembersPage(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        newBelieversOnly: true,
      );
      if (!mounted) return;
      setState(() {
        _members = page.members;
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
        _members = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MemberService.messageFromFirestoreException(error, context.l10n),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
        _members = [];
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      if (query == _activeSearchQuery) return;
      _activeSearchQuery = query;
      _lastDocument = null;
      _hasMore = true;
      _loadFirstPage();
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _openEdit(BuildContext context, ChurchMember member) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMemberScreen(
          registeredBy: widget.registeredBy,
          churchId: widget.permissions.churchId,
          memberService: widget.memberService,
          memberToEdit: member,
          permissions: widget.permissions,
        ),
      ),
    );
    if (!mounted) return;
    await _loadFirstPage(forceRefresh: true);
  }

  Future<void> _exportToExcel() async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      final members = await _service.fetchAllMembersForExport(
        churchId: _churchId,
        searchQuery: _activeSearchQuery,
        newBelieversOnly: true,
      );
      if (!mounted) return;
      if (members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.commonNoMatches)),
        );
        return;
      }
      await _excelExportService.shareMembers(members);
    } on MembersExcelExportException catch (e) {
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

  Future<void> _confirmDelete(BuildContext context, ChurchMember member) async {
    final l10n = context.l10n;
    final id = member.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.membersListDeleteTitle),
        content: Text(l10n.commonDeleteConfirm(member.fullName)),
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
      await _service.deleteMember(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.membersListDeleted)),
      );
      await _loadFirstPage(forceRefresh: true);
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MemberService.messageFromFirestoreException(e, context.l10n),
          ),
        ),
      );
    }
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        key: const ValueKey('members_list_search'),
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: l10n.membersListSearchHint,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    AppLocalizations l10n,
    ChurchMember member,
  ) {
    final subtitleParts = <String>[
      member.phone,
      if (member.assignmentKindLabel(l10n) != null)
        member.assignmentKindLabel(l10n)!,
      if (member.isPastoralLeaderAssignment &&
          member.assignedLeaderName != null)
        l10n.membersListLeaderPrefix(member.assignedLeaderName!),
      if (member.isCellMemberAssignment && member.assignedCellCode != null)
        l10n.cellRegDiscipleFromCell(member.assignedCellCode!),
      if (member.locality != null) member.locality!,
      l10n.membersListDatePrefix(_formatDate(member.formDate)),
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
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => MemberDetailScreen(
                      member: member,
                      registeredBy: widget.registeredBy,
                      memberService: _service,
                      permissions: widget.permissions,
                    ),
                  ),
                );
              case 'edit':
                _openEdit(context, member);
              case 'delete':
                _confirmDelete(context, member);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'view',
              child: Text(l10n.membersMapViewDetail),
            ),
            if (widget.permissions.canManageMembers) ...[
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
        onTap: () {
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
    return const SizedBox(height: 88);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.membersListTitle),
        actions: [
          if (!_loading)
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
      ),
      floatingActionButton: widget.permissions.canRegisterMember
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => RegisterMemberScreen(
                      registeredBy: widget.registeredBy,
                      churchId: widget.permissions.churchId,
                      memberService: _service,
                      permissions: widget.permissions,
                    ),
                  ),
                );
                if (created == true && mounted) {
                  await _loadFirstPage(forceRefresh: true);
                }
              },
              icon: const Icon(Icons.person_add),
              label: Text(l10n.commonNew),
            )
          : null,
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading && _members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.membersListLoadError,
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

    if (_members.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(l10n),
          Expanded(
            child: Center(
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
                      _activeSearchQuery.isEmpty
                          ? l10n.membersListEmptyTitle
                          : l10n.commonNoMatches,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (_activeSearchQuery.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.membersListEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFirstPage(forceRefresh: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(l10n),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              itemCount: _members.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= _members.length) {
                  return _buildListFooter(l10n);
                }
                return _buildMemberTile(context, l10n, _members[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
