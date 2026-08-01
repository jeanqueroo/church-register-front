import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/app_user_role.dart';
import '../../auth/services/user_profile_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../models/church_leader.dart';
import '../services/leader_service.dart';
import 'leader_assigned_members_screen.dart';
import 'register_leader_screen.dart';

class LeaderDetailScreen extends StatefulWidget {
  const LeaderDetailScreen({
    super.key,
    required this.leader,
    required this.registeredBy,
    this.leaderService,
    this.permissions,
  });

  final ChurchLeader leader;
  final String registeredBy;
  final LeaderService? leaderService;
  final AppPermissions? permissions;

  @override
  State<LeaderDetailScreen> createState() => _LeaderDetailScreenState();
}

class _LeaderDetailScreenState extends State<LeaderDetailScreen> {
  late bool _isBlocked = widget.leader.isBlocked;
  bool _actionInProgress = false;

  AppPermissions get _permissions =>
      widget.permissions ?? AppPermissions.fromRoles([]);

  ChurchLeader get leader => widget.leader;

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterLeaderScreen(
          registeredBy: widget.registeredBy,
          churchId: _permissions.churchId,
          leaderService: widget.leaderService,
          leaderToEdit: leader,
          permissions: _permissions,
        ),
      ),
    );
  }

  Future<void> _toggleBlock(BuildContext context, {required bool block}) async {
    if (!_permissions.canManageAll || _actionInProgress) return;

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

    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await (widget.leaderService ?? LeaderService()).setLeaderBlocked(
        id: id,
        blocked: block,
        authUserId: leader.authUserId,
        updatedBy: widget.registeredBy,
      );
      if (!mounted) return;
      setState(() => _isBlocked = block);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(block ? l10n.leadersBlocked : l10n.leadersUnblocked)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LeaderService.messageFromFirestoreException(e, context.l10n)),
        ),
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  List<_Row> _leadershipRows(AppLocalizations l10n) {
    return [
      _Row(l10n.leaderDetailLastName, leader.lastName),
      _Row(l10n.leaderDetailFirstNames, leader.firstName),
      _Row(
        l10n.memberDetailIdDocument,
        leader.idDocumentType?.localizedLabel(l10n),
      ),
      _Row(l10n.memberDetailIdDocumentNumber, leader.idDocumentNumber),
      _Row(l10n.memberDetailBirthDate, _formatDate(leader.birthDate)),
      _Row(
        l10n.memberDetailAge,
        leader.age != null ? l10n.memberAgeYears(leader.age!) : null,
      ),
      _Row(l10n.memberDetailOccupation, leader.occupation),
      _Row(
        l10n.memberDetailGender,
        leader.gender?.localizedLabel(l10n),
      ),
      _Row(
        l10n.leaderDetailChurchOffice,
        leader.churchOffice?.localizedLabel(l10n),
      ),
    ];
  }

  List<_Row> _addressRows(AppLocalizations l10n) {
    return [
      _Row(l10n.addressStreetOptional, leader.street),
      _Row(l10n.addressNumber, leader.streetNumber),
      _Row(l10n.addressNeighborhood, leader.neighborhood),
      _Row(l10n.addressLocality, leader.locality),
      _Row(l10n.addressStateProvince, leader.stateProvince),
      _Row(l10n.addressPostalCode, leader.postalCode),
    ];
  }

  List<_Row> _cellContactRows(AppLocalizations l10n) {
    return [
      _Row(l10n.memberDetailCell, leader.cellCode),
      _Row(l10n.emailLabel, leader.email),
      _Row(l10n.leaderDetailMobile, leader.mobilePhone),
    ];
  }

  List<_Row> _registrationRows(AppLocalizations l10n) {
    return [
      _Row(l10n.memberDetailRegisteredBy, leader.registeredBy),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(leader.fullName),
        actions: [
          if (_permissions.canManageAll) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.commonEdit,
              onPressed: _actionInProgress ? null : () => _edit(context),
            ),
            IconButton(
              icon: Icon(_isBlocked ? Icons.lock_open_outlined : Icons.block_outlined),
              tooltip: _isBlocked ? l10n.commonUnblock : l10n.commonBlock,
              onPressed: _actionInProgress
                  ? null
                  : () => _toggleBlock(context, block: !_isBlocked),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_isBlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.block,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  title: Text(
                    l10n.commonBlocked,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          _Section(
            title: l10n.leaderDetailSectionLeadership,
            rows: _leadershipRows(l10n),
          ),
          if (leader.authUserId != null && leader.authUserId!.isNotEmpty)
            _LeaderRolesSection(authUserId: leader.authUserId!, l10n: l10n),
          _Section(
            title: l10n.memberDetailSectionAddress,
            rows: _addressRows(l10n),
          ),
          _Section(
            title: l10n.leaderDetailSectionCellContact,
            rows: _cellContactRows(l10n),
          ),
          _Section(
            title: l10n.memberDetailSectionRegistration,
            rows: _registrationRows(l10n),
          ),
          if (_permissions.canManageAll ||
              _permissions.isLeader ||
              _permissions.canViewSupervisedLeaderMembers) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LeaderAssignedMembersScreen(
                      leader: leader,
                      registeredBy: widget.registeredBy,
                      permissions: _permissions,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.people_outlined),
              label: Text(l10n.leaderDetailViewMembers),
            ),
            const SizedBox(height: 12),
          ],
          if (_permissions.canManageAll) ...[
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.leaderDetailEditLeader),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _actionInProgress
                  ? null
                  : () => _toggleBlock(context, block: !_isBlocked),
              icon: Icon(
                _isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
              ),
              label: Text(
                _isBlocked
                    ? l10n.leaderDetailUnblockLeader
                    : l10n.leaderDetailBlockLeader,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaderRolesSection extends StatelessWidget {
  const _LeaderRolesSection({
    required this.authUserId,
    required this.l10n,
  });

  final String authUserId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserProfileService().fetchProfileDoc(authUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final roles = snapshot.hasData
            ? AppUserRole.parseList(snapshot.data!.data()?['roles'])
            : <String>[];
        if (roles.isEmpty) return const SizedBox.shrink();

        final labels = roles
            .map((role) => AppUserRole.localizedLabel(role, l10n))
            .toList()
          ..sort();
        return _Section(
          title: l10n.leaderDetailSectionRoles,
          rows: [_Row(l10n.leaderDetailPermissions, labels.join(', '))],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.hasValue).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: visible
                    .map(
                      (row) => ListTile(
                        title: Text(row.label),
                        subtitle: Text(row.value!),
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  bool get hasValue => value != null && value!.trim().isNotEmpty;
}
