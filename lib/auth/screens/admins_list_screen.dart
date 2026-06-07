import 'package:flutter/material.dart';

import '../../church/services/church_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../leaders/services/leader_service.dart';
import '../models/admin_user_record.dart';
import '../models/app_permissions.dart';
import '../services/user_profile_service.dart';
import '../widgets/role_gate.dart';
import 'register_admin_screen.dart';

/// Lista de administradores de iglesia (editar y bloquear).
class AdminsListScreen extends StatelessWidget {
  const AdminsListScreen({
    super.key,
    required this.updatedBy,
    required this.permissions,
    this.userProfileService,
    this.churchService,
    this.leaderService,
  });

  final String updatedBy;
  final AppPermissions permissions;
  final UserProfileService? userProfileService;
  final ChurchService? churchService;
  final LeaderService? leaderService;

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewAdminsList,
      deniedMessage: context.l10n.adminsDenied,
      child: _AdminsListBody(
        updatedBy: updatedBy,
        permissions: permissions,
        userProfileService: userProfileService,
        churchService: churchService,
        leaderService: leaderService,
      ),
    );
  }
}

class _AdminsListBody extends StatefulWidget {
  const _AdminsListBody({
    required this.updatedBy,
    required this.permissions,
    this.userProfileService,
    this.churchService,
    this.leaderService,
  });

  final String updatedBy;
  final AppPermissions permissions;
  final UserProfileService? userProfileService;
  final ChurchService? churchService;
  final LeaderService? leaderService;

  @override
  State<_AdminsListBody> createState() => _AdminsListBodyState();
}

class _AdminsListBodyState extends State<_AdminsListBody> {
  final _searchController = TextEditingController();
  late final UserProfileService _userProfileService;
  late final ChurchService _churchService;
  late final LeaderService _leaderService;
  Map<String, String> _churchNames = {};
  Map<String, ({String firstName, String lastName})> _leaderNames = {};
  bool _hideBlocked = false;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _userProfileService = widget.userProfileService ?? UserProfileService();
    _churchService = widget.churchService ?? ChurchService();
    _leaderService = widget.leaderService ?? LeaderService();
    _loadChurchNames();
    _loadLeaderNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChurchNames() async {
    try {
      final churches = await _churchService.fetchChurches();
      if (!mounted) return;
      final noName = context.l10n.commonNoName;
      setState(() {
        _churchNames = {
          for (final c in churches)
            c.id: c.name.isNotEmpty ? c.name : noName,
        };
      });
    } catch (_) {}
  }

  Future<void> _loadLeaderNames() async {
    try {
      final leaders = await _leaderService.fetchAllLeaders();
      if (!mounted) return;
      setState(() {
        _leaderNames = {
          for (final l in leaders)
            if (l.id != null && l.id!.isNotEmpty)
              l.id!: (firstName: l.firstName, lastName: l.lastName),
        };
      });
    } catch (_) {}
  }

  AdminUserRecord _enrichAdmin(AdminUserRecord admin) {
    final leaderId = admin.leaderId;
    if (leaderId == null || leaderId.isEmpty) return admin;
    final names = _leaderNames[leaderId];
    if (names == null) return admin;
    return admin.withLeaderNames(
      firstName: names.firstName,
      lastName: names.lastName,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _churchLabel(String? churchId) {
    final l10n = context.l10n;
    if (churchId == null || churchId.isEmpty) return l10n.adminsNoChurch;
    return _churchNames[churchId] ?? l10n.adminsChurchLabel(churchId);
  }

  void _openCreate() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterAdminScreen(
          registeredBy: widget.updatedBy,
          permissions: widget.permissions,
          userProfileService: _userProfileService,
          churchService: _churchService,
          leaderService: _leaderService,
        ),
      ),
    );
  }

  void _openEdit(AdminUserRecord admin) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterAdminScreen(
          registeredBy: widget.updatedBy,
          permissions: widget.permissions,
          userProfileService: _userProfileService,
          churchService: _churchService,
          leaderService: _leaderService,
          adminToEdit: admin,
        ),
      ),
    );
  }

  bool _matchesSearch(AdminUserRecord admin, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      admin.displayName,
      admin.email,
      _churchLabel(admin.churchId),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  List<AdminUserRecord> _applyFilters(List<AdminUserRecord> admins) {
    return admins
        .where((a) => !_hideBlocked || !a.isBlocked)
        .where((a) => _matchesSearch(a, _searchController.text))
        .toList();
  }

  Future<void> _confirmBlock(AdminUserRecord admin, {required bool block}) async {
    if (!widget.permissions.canBlockAdmin || _actionInProgress) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? l10n.adminsBlockTitle : l10n.adminsUnblockTitle),
        content: Text(
          block
              ? l10n.adminsBlockConfirm(admin.displayName)
              : l10n.adminsUnblockConfirm(admin.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(block ? l10n.commonBlock : l10n.commonUnblock),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await _userProfileService.setAdminBlocked(
        uid: admin.uid,
        blocked: block,
        updatedBy: widget.updatedBy,
      );
      if (!mounted) return;
      _showMessage(block ? l10n.adminsBlocked : l10n.adminsUnblocked);
    } catch (e) {
      if (!mounted) return;
      _showMessage(UserProfileService.messageFromException(e, context.l10n));
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _onMenuAction(String action, AdminUserRecord admin) {
    switch (action) {
      case 'edit':
        _openEdit(admin);
      case 'block':
        _confirmBlock(admin, block: true);
      case 'unblock':
        _confirmBlock(admin, block: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminsTitle),
      ),
      floatingActionButton: widget.permissions.canRegisterAdmin
          ? FloatingActionButton.extended(
              onPressed: _actionInProgress ? null : _openCreate,
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.commonNew),
            )
          : null,
      body: StreamBuilder<List<AdminUserRecord>>(
        stream: _userProfileService.watchChurchAdmins(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminsLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          }

          final admins =
              (snapshot.data ?? []).map(_enrichAdmin).toList();
          final filtered = _applyFilters(admins);
          final blockedCount = admins.where((a) => a.isBlocked).length;

          if (admins.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.adminsEmpty,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (widget.permissions.canRegisterAdmin)
                      FilledButton.icon(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.person_add_outlined),
                        label: Text(l10n.adminsRegister),
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
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.adminsSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (blockedCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: FilterChip(
                    label: Text(
                      _hideBlocked
                          ? l10n.adminsShowBlocked(blockedCount)
                          : l10n.adminsHideBlocked(blockedCount),
                    ),
                    selected: _hideBlocked,
                    onSelected: _actionInProgress
                        ? null
                        : (v) => setState(() => _hideBlocked = v),
                  ),
                ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _searchController.text.trim().isEmpty && _hideBlocked
                          ? l10n.adminsAllBlocked
                          : l10n.commonNoMatches,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final admin = filtered[index];
                      final blocked = admin.isBlocked;

                      return Card(
                        color: blocked
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : null,
                        child: ListTile(
                          isThreeLine: true,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Icon(
                              Icons.admin_panel_settings,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(admin.displayName)),
                              if (blocked)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Chip(
                                    label: Text(l10n.commonBlocked),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(admin.email),
                              const SizedBox(height: 2),
                              Text(_churchLabel(admin.churchId)),
                            ],
                          ),
                          onTap: _actionInProgress
                              ? null
                              : () => _openEdit(admin),
                          trailing: PopupMenuButton<String>(
                            enabled: !_actionInProgress,
                            onSelected: (value) => _onMenuAction(value, admin),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(l10n.commonEdit),
                              ),
                              if (widget.permissions.canBlockAdmin)
                                PopupMenuItem(
                                  value: blocked ? 'unblock' : 'block',
                                  child: Text(
                                    blocked
                                        ? l10n.commonUnblock
                                        : l10n.commonBlock,
                                  ),
                                ),
                            ],
                          ),
                        ),
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
