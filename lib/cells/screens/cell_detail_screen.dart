import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/locale/weekday_labels.dart';
import '../../l10n/app_localizations.dart';
import '../cell_member_capacity.dart';
import '../models/cell_disciple.dart';
import '../models/church_cell.dart';
import '../services/cell_service.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';
import '../../members/screens/register_member_screen.dart';
import 'assign_cell_members_screen.dart';
import 'register_cell_disciple_screen.dart';
import 'register_cell_screen.dart';

class CellDetailScreen extends StatefulWidget {
  const CellDetailScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.cellService,
    this.permissions,
    this.actingLeaderId,
  });

  final ChurchCell cell;
  final String registeredBy;
  final CellService? cellService;
  final AppPermissions? permissions;
  final String? actingLeaderId;

  @override
  State<CellDetailScreen> createState() => _CellDetailScreenState();
}

class _CellDetailScreenState extends State<CellDetailScreen> {
  late ChurchCell _cell;

  @override
  void initState() {
    super.initState();
    _cell = widget.cell;
  }

  AppPermissions get _permissions =>
      widget.permissions ?? AppPermissions.adminDefault();

  CellService get _cellService => widget.cellService ?? CellService();

  MemberService get _memberService => MemberService();

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterCellScreen(
          registeredBy: widget.registeredBy,
          churchId: _cell.churchId ?? _permissions.churchId,
          cellToEdit: _cell,
          cellService: widget.cellService,
          permissions: _permissions,
        ),
      ),
    );
    if (updated != true || !mounted) return;

    final cellId = _cell.id;
    if (cellId == null || cellId.isEmpty) return;

    final fresh = await _cellService.fetchCellById(cellId);
    if (fresh != null && mounted) {
      setState(() => _cell = fresh);
    }
  }

  Future<void> _openRegisterMember() async {
    final cellId = _cell.id;
    if (cellId == null || cellId.isEmpty) return;

    final count = await _memberService.countMembersInCell(cellId);
    if (!CellMemberCapacity.canAssignAnother(
      currentCount: count,
      cell: _cell,
      actingLeaderId: widget.actingLeaderId,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MemberService.messageForCellAssignmentLimit(context.l10n),
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMemberScreen(
          registeredBy: widget.registeredBy,
          churchId: _cell.churchId ?? _permissions.churchId,
          cellToAssign: _cell,
          permissions: _permissions,
          actingLeaderId: widget.actingLeaderId,
        ),
      ),
    );
  }

  Future<void> _openAssignMembers() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AssignCellMembersScreen(
          cell: _cell,
          registeredBy: widget.registeredBy,
          permissions: _permissions,
          actingLeaderId: widget.actingLeaderId,
        ),
      ),
    );
  }

  Future<void> _openRegisterDisciple() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterCellDiscipleScreen(
          cell: _cell,
          registeredBy: widget.registeredBy,
          cellService: widget.cellService,
          permissions: _permissions,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDisciple(CellDisciple disciple) async {
    final l10n = context.l10n;
    final cellId = _cell.id;
    final discipleId = disciple.id;
    if (cellId == null || discipleId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cellDiscipleDeleteTitle),
        content: Text(l10n.commonDeleteConfirm(disciple.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _cellService.deleteDisciple(
        cellId: cellId,
        discipleId: discipleId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellDiscipleDeleted)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CellService.messageFromFirestoreException(e, context.l10n),
          ),
        ),
      );
    }
  }

  List<_Row> _cellRows(AppLocalizations l10n) {
    return [
      _Row(l10n.cellRegCode, _cell.code),
      _Row(l10n.cellRegName, _cell.name),
      _Row(
        l10n.cellRegMeetingDay,
        localizedWeekday(l10n, _cell.cellDay),
      ),
      _Row(l10n.memberDetailSectionAddress, _cell.formattedAddress),
      _Row(l10n.cellRegSectionLeader, _cell.leaderName),
      _Row(l10n.cellRegNotes, _cell.notes),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cellId = _cell.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_cell.displayLabel),
        actions: [
          if (_permissions.canEditCell && cellId != null && cellId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.commonEdit,
              onPressed: _openEdit,
            ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(l10n, cellId),
      body: cellId == null || cellId.isEmpty
          ? Center(child: Text(l10n.cellDiscipleCellMissing))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _Section(title: l10n.cellRegSectionData, rows: _cellRows(l10n)),
                const SizedBox(height: 16),
                if (_permissions.canEditCell) ...[
                  OutlinedButton.icon(
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.cellEditTitle),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_permissions.canRegisterCellDisciple) ...[
                  FilledButton.icon(
                    onPressed: _openRegisterDisciple,
                    icon: const Icon(Icons.person_add_outlined),
                    label: Text(l10n.cellDiscipleAdd),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_permissions.canAssignCellMembers) ...[
                  OutlinedButton.icon(
                    onPressed: _openAssignMembers,
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(l10n.cellMemberAssignAction),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.cellMemberListTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<ChurchMember>>(
                  stream: _memberService.watchMembersInCell(cellId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data ?? [];
                    if (members.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          l10n.cellMemberListEmpty,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...members.map((member) {
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
                              subtitle: Text(member.phone),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                Text(
                  l10n.cellDiscipleListTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<CellDisciple>>(
                  stream: _cellService.watchDisciples(cellId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final disciples = snapshot.data ?? [];
                    if (disciples.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          l10n.cellDiscipleListEmpty,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      );
                    }

                    return Column(
                      children: disciples.map((disciple) {
                        final parts = <String>[
                          disciple.mobilePhone,
                          if (disciple.email != null && disciple.email!.isNotEmpty)
                            disciple.email!,
                        ];

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                disciple.fullName.isNotEmpty
                                    ? disciple.fullName[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(disciple.fullName),
                            subtitle: Text(parts.join(' · ')),
                            trailing: _permissions.canRegisterCellDisciple
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: l10n.commonDelete,
                                    onPressed: () =>
                                        _confirmDeleteDisciple(disciple),
                                  )
                                : null,
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                showDragHandle: true,
                                builder: (ctx) => _DiscipleDetailSheet(
                                  disciple: disciple,
                                  l10n: l10n,
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget? _buildFloatingActionButton(AppLocalizations l10n, String? cellId) {
    if (cellId == null || cellId.isEmpty) return null;

    final actions = <Widget>[];

    if (_permissions.canRegisterMember) {
      actions.add(
        FloatingActionButton.extended(
          heroTag: 'cell_register_member',
          onPressed: _openRegisterMember,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(l10n.cellMemberRegisterNew),
        ),
      );
    }

    if (_permissions.canRegisterCellDisciple) {
      actions.add(
        FloatingActionButton.extended(
          heroTag: 'cell_register_disciple',
          onPressed: _openRegisterDisciple,
          icon: const Icon(Icons.person_add_outlined),
          label: Text(l10n.cellDiscipleAdd),
        ),
      );
    }

    if (actions.isEmpty) return null;
    if (actions.length == 1) return actions.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < actions.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: actions[i],
          ),
      ],
    );
  }
}

class _DiscipleDetailSheet extends StatelessWidget {
  const _DiscipleDetailSheet({
    required this.disciple,
    required this.l10n,
  });

  final CellDisciple disciple;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final rows = <_Row>[
      _Row(l10n.leaderRegLastName, disciple.lastName),
      _Row(l10n.leaderRegFirstNames, disciple.firstName),
      _Row(l10n.memberDetailGender, disciple.gender?.localizedLabel(l10n)),
      _Row(
        l10n.memberDetailIdDocument,
        disciple.idDocumentType?.localizedLabel(l10n),
      ),
      _Row(l10n.memberDetailIdDocumentNumber, disciple.idDocumentNumber),
      _Row(
        l10n.memberDetailAge,
        disciple.age != null ? l10n.memberAgeYears(disciple.age!) : null,
      ),
      _Row(l10n.memberDetailSectionAddress, disciple.formattedAddress),
      _Row(l10n.leaderDetailMobile, disciple.mobilePhone),
      _Row(l10n.emailLabel, disciple.email),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              disciple.fullName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...rows.where((row) => row.hasValue).map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row.label),
                    subtitle: Text(row.value!),
                    dense: true,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((row) => row.hasValue).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
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
      ],
    );
  }
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  bool get hasValue => value != null && value!.trim().isNotEmpty;
}
