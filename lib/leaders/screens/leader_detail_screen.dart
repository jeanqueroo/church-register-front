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

class LeaderDetailScreen extends StatelessWidget {
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

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.fromRoles([]);

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterLeaderScreen(
          registeredBy: registeredBy,
          churchId: _permissions.churchId,
          leaderService: leaderService,
          leaderToEdit: leader,
          permissions: _permissions,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
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
      await (leaderService ?? LeaderService()).deleteLeader(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.leaderDetailDeleted)),
      );
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LeaderService.messageFromFirestoreException(e, context.l10n)),
        ),
      );
    }
  }

  List<_Row> _leadershipRows(AppLocalizations l10n) {
    return [
      _Row(l10n.leaderDetailLastName, leader.lastName),
      _Row(l10n.leaderDetailFirstNames, leader.firstName),
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
              onPressed: () => _edit(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.commonDelete,
              onPressed: () => _delete(context),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
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
                      registeredBy: registeredBy,
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
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.leaderDetailDeleteLeader),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
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
