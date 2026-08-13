import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../church/services/church_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/locale/weekday_labels.dart';
import '../../l10n/app_localizations.dart';
import '../models/cell_attendance_session.dart';
import '../models/cell_helper.dart';
import '../models/church_cell.dart';
import '../services/cell_attendance_service.dart';
import '../services/cell_service.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';
import '../../leaders/services/leader_service.dart';
import 'assign_cell_members_screen.dart';
import 'register_cell_attendance_screen.dart';
import 'register_cell_member_screen.dart';
import 'register_cell_screen.dart';

class CellDetailScreen extends StatefulWidget {
  const CellDetailScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.cellService,
    this.permissions,
    this.actingLeaderId,
    this.supervisedLeaderIds = const [],
  });

  final ChurchCell cell;
  final String registeredBy;
  final CellService? cellService;
  final AppPermissions? permissions;
  final String? actingLeaderId;
  final List<String> supervisedLeaderIds;

  @override
  State<CellDetailScreen> createState() => _CellDetailScreenState();
}

class _CellDetailScreenState extends State<CellDetailScreen> {
  late ChurchCell _cell;
  StreamSubscription<ChurchCell?>? _cellSubscription;
  bool _savingHelpers = false;
  bool _claimingLeadership = false;
  String? _churchAlias;

  @override
  void initState() {
    super.initState();
    _cell = widget.cell;
    _listenToCellUpdates();
    _loadChurchAlias();
  }

  @override
  void dispose() {
    _cellSubscription?.cancel();
    super.dispose();
  }

  AppPermissions get _permissions =>
      widget.permissions ?? AppPermissions.adminDefault();

  CellService get _cellService => widget.cellService ?? CellService();

  CellAttendanceService get _attendanceService => CellAttendanceService();

  MemberService get _memberService => MemberService();

  bool get _canRegisterAttendance => _permissions.canRegisterCellAttendance(
        _cell,
        actingLeaderId: widget.actingLeaderId,
      );

  bool get _canManageHelpers => _permissions.canManageHelpersForCell(
        _cell,
        actingLeaderId: widget.actingLeaderId,
      );

  Future<void> _loadChurchAlias() async {
    final churchId =
        (_cell.churchId ?? _permissions.churchId)?.trim();
    if (churchId == null || churchId.isEmpty) return;
    try {
      final church = await ChurchService().fetchChurch(churchId);
      if (!mounted) return;
      setState(() => _churchAlias = church?.alias?.trim());
    } catch (_) {}
  }

  void _listenToCellUpdates() {
    final cellId = widget.cell.id;
    if (cellId == null || cellId.isEmpty) return;

    _cellSubscription = _cellService.watchCellById(cellId).listen((fresh) {
      if (fresh != null && mounted) {
        setState(() => _cell = fresh);
      }
    });
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterCellScreen(
          registeredBy: widget.registeredBy,
          churchId: _cell.churchId ?? _permissions.churchId,
          cellToEdit: _cell,
          cellService: widget.cellService,
          permissions: _permissions,
          ensureLeaderId: widget.actingLeaderId,
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
    if (!_permissions.canRegisterNewCellMember(
      _cell,
      currentMemberCount: count,
      actingLeaderId: widget.actingLeaderId,
      supervisedLeaderIds: widget.supervisedLeaderIds,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MemberService.messageForCellAssignmentLeaderOnly(context.l10n),
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterCellMemberScreen(
          cell: _cell,
          registeredBy: widget.registeredBy,
          churchId: _cell.churchId ?? _permissions.churchId,
          permissions: _permissions,
          actingLeaderId: widget.actingLeaderId,
          supervisedLeaderIds: widget.supervisedLeaderIds,
        ),
      ),
    );
  }

  Future<void> _openRegisterAttendance() async {
    final cellId = _cell.id;
    if (cellId == null || cellId.isEmpty) return;

    final count = await _memberService.countMembersInCell(cellId);
    if (count == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cellAttendanceNoDisciples)),
      );
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterCellAttendanceScreen(
          cell: _cell,
          registeredBy: widget.registeredBy,
          actingLeaderId: widget.actingLeaderId,
          permissions: _permissions,
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
          supervisedLeaderIds: widget.supervisedLeaderIds,
        ),
      ),
    );
  }

  Future<void> _openSelectHelpers(List<ChurchMember> members) async {
    final l10n = context.l10n;
    final cellId = _cell.id;
    if (cellId == null || cellId.isEmpty || members.isEmpty) return;

    final selectedIds = _cell.helpers.map((helper) => helper.memberId).toSet();

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final sheetSelected = Set<String>.from(selectedIds);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.cellHelpersSelectAction,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.cellHelpersHint(ChurchCell.maxHelpers),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.cellHelpersCount(
                          sheetSelected.length,
                          ChurchCell.maxHelpers,
                        ),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final memberId = member.id;
                          if (memberId == null || memberId.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final isSelected = sheetSelected.contains(memberId);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setSheetState(() {
                                if (checked == true) {
                                  if (sheetSelected.length >=
                                      ChurchCell.maxHelpers) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.cellHelpersMaxReached(
                                            ChurchCell.maxHelpers,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  sheetSelected.add(memberId);
                                } else {
                                  sheetSelected.remove(memberId);
                                }
                              });
                            },
                            title: Text(member.fullName),
                            subtitle: Text(member.phone),
                            secondary: CircleAvatar(
                              child: Text(
                                member.fullName.isNotEmpty
                                    ? member.fullName[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, sheetSelected),
                      child: Text(l10n.commonSave),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    await _saveHelpers(members, result);
  }

  Future<void> _saveHelpers(
    List<ChurchMember> members,
    Set<String> selectedIds,
  ) async {
    final l10n = context.l10n;
    final cellId = _cell.id;
    if (cellId == null || cellId.isEmpty) return;

    final membersById = {
      for (final member in members)
        if (member.id != null && member.id!.isNotEmpty) member.id!: member,
    };

    final helpers = selectedIds
        .map((id) => membersById[id])
        .whereType<ChurchMember>()
        .map(
          (member) => CellHelper(
            memberId: member.id!,
            fullName: member.fullName,
          ),
        )
        .toList();

    setState(() => _savingHelpers = true);
    try {
      await _cellService.updateCellHelpers(
        cellId: cellId,
        helpers: helpers,
      );
      await _memberService.clearNewBelieverForCellHelpers(selectedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellHelpersSaved)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CellService.messageFromFirestoreException(e, l10n),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingHelpers = false);
    }
  }

  bool get _canClaimLeadership => _permissions.canClaimOwnCellLeadership(
        _cell,
        actingLeaderId: widget.actingLeaderId,
      );

  bool _blockingInProgress = false;

  Future<void> _toggleBlock({required bool block}) async {
    if (!_permissions.canBlockCell || _blockingInProgress) return;
    final l10n = context.l10n;
    final cellId = _cell.id;
    if (cellId == null || cellId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(block ? l10n.cellsBlockTitle : l10n.cellsUnblockTitle),
        content: Text(
          block
              ? l10n.cellsBlockConfirm(_cell.displayLabel)
              : l10n.cellsUnblockConfirm(_cell.displayLabel),
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

    setState(() => _blockingInProgress = true);
    try {
      await _cellService.setCellBlocked(cellId: cellId, blocked: block);
      if (!mounted) return;
      _showSnack(block ? l10n.cellsBlocked : l10n.cellsUnblocked);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showSnack(CellService.messageFromFirestoreException(e, l10n));
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.memberSaveUnexpectedError);
    } finally {
      if (mounted) setState(() => _blockingInProgress = false);
    }
  }

  Widget _blockedBanner(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.block_outlined,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.cellsBlockedBanner,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimCellLeadership() async {
    final l10n = context.l10n;
    final cellId = _cell.id;
    final actingLeaderId = widget.actingLeaderId?.trim();
    if (cellId == null ||
        cellId.isEmpty ||
        actingLeaderId == null ||
        actingLeaderId.isEmpty ||
        !_canClaimLeadership) {
      _showSnack(l10n.cellClaimLeadershipDenied);
      return;
    }

    setState(() => _claimingLeadership = true);
    try {
      final busyLeaderIds = await _cellService.fetchLeaderIdsWithAssignedCell(
        churchId: _cell.churchId,
        excludeCellId: cellId,
      );
      if (busyLeaderIds.contains(actingLeaderId)) {
        if (!mounted) return;
        _showSnack(l10n.cellClaimLeadershipAlreadyAssigned);
        return;
      }

      final leader = await LeaderService().fetchLeaderById(actingLeaderId);
      if (leader == null) {
        if (!mounted) return;
        _showSnack(l10n.leaderRecordNotFound);
        return;
      }

      await _cellService.updateCell(
        cellId: cellId,
        cell: ChurchCell(
          id: _cell.id,
          code: _cell.code,
          name: _cell.name,
          street: _cell.street,
          streetNumber: _cell.streetNumber,
          neighborhood: _cell.neighborhood,
          locality: _cell.locality,
          stateProvince: _cell.stateProvince,
          postalCode: _cell.postalCode,
          latitude: _cell.latitude,
          longitude: _cell.longitude,
          cellDay: _cell.cellDay,
          leaderId: actingLeaderId,
          leaderName: leader.fullName,
          notes: _cell.notes,
          helpers: _cell.helpers,
          registeredAt: _cell.registeredAt,
          registeredBy: _cell.registeredBy,
          churchId: _cell.churchId,
          memberCount: _cell.memberCount,
          isBlocked: _cell.isBlocked,
        ),
        previousCode: _cell.code,
      );

      if (!mounted) return;
      _showSnack(l10n.cellClaimLeadershipSuccess);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showSnack(CellService.messageFromFirestoreException(e, l10n));
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.memberSaveUnexpectedError);
    } finally {
      if (mounted) setState(() => _claimingLeadership = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _claimLeadershipBanner(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cellClaimLeadershipTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cellClaimLeadershipSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _claimingLeadership ? null : _claimCellLeadership,
              icon: _claimingLeadership
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_pin_outlined),
              label: Text(l10n.cellClaimLeadershipAction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceHistorySection(AppLocalizations l10n, String cellId) {
    return StreamBuilder<List<CellAttendanceSession>>(
      stream: _attendanceService.watchSessions(cellId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) return const SizedBox.shrink();

        final recent = sessions.take(3).toList();
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.history_outlined),
              title: Text(
                l10n.cellAttendanceHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Text(l10n.cellAttendanceHistoryRecentCount(recent.length)),
              children: recent.map((session) {
                final dateText = _formatSessionDate(session.sessionDate);
                final subtitleParts = <String>[
                  '${l10n.cellAttendanceSessionTime}: ${session.sessionTime}',
                  l10n.cellAttendancePresentCount(
                    session.presentCount,
                    session.totalCount,
                  ),
                ];
                if (session.dayDiffersFromRegistered &&
                    session.noteDayChangeForSession) {
                  subtitleParts.add(l10n.cellAttendanceDayChangedBadge);
                }
                if (session.locationDiffersFromRegistered &&
                    session.noteLocationChangeForSession) {
                  subtitleParts.add(l10n.cellAttendanceLocationChangedBadge);
                }
                if (session.offeringCollected != null &&
                    session.offeringCollected!.trim().isNotEmpty) {
                  subtitleParts.add(
                    l10n.cellAttendanceOfferingSummary(
                      session.offeringCollected!.trim(),
                    ),
                  );
                }
                if (session.observations != null &&
                    session.observations!.trim().isNotEmpty) {
                  subtitleParts.add(session.observations!.trim());
                }

                return ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(dateText),
                  subtitle: Text(
                    [
                      ...subtitleParts,
                      if (session.place.trim().isNotEmpty) session.place.trim(),
                    ].join('\n'),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _formatSessionDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  List<_Row> _cellRows(AppLocalizations l10n) {
    return [
      _Row(l10n.cellRegCode, _cell.code),
      _Row(l10n.cellRegName, _cell.name),
      _Row(
        l10n.churchRegAlias,
        (_churchAlias != null && _churchAlias!.isNotEmpty)
            ? _churchAlias
            : l10n.cellRegAliasEmpty,
      ),
      _Row(
        l10n.cellRegMeetingDay,
        localizedWeekday(l10n, _cell.cellDay),
      ),
      _Row(l10n.memberDetailSectionAddress, _cell.formattedAddress),
      _Row(l10n.cellRegSectionLeader, _cell.leaderName),
      _Row(l10n.cellRegNotes, _cell.notes),
    ];
  }

  Widget _helpersSection(
    AppLocalizations l10n,
    List<ChurchMember> members,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.handshake_outlined),
          title: Text(
            l10n.cellHelpersTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(
            l10n.cellHelpersCount(
              _cell.helpers.length,
              ChurchCell.maxHelpers,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l10n.cellHelpersHint(ChurchCell.maxHelpers),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (_cell.helpers.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  l10n.cellHelpersEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ..._cell.helpers.map((helper) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      helper.fullName.isNotEmpty
                          ? helper.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(helper.fullName),
                  trailing: Chip(
                    label: Text(l10n.cellHelpersBadge),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            if (_canManageHelpers && members.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: _savingHelpers
                      ? null
                      : () => _openSelectHelpers(members),
                  icon: _savingHelpers
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.handshake_outlined),
                  label: Text(l10n.cellHelpersSelectAction),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _disciplesSection(
    AppLocalizations l10n,
    List<ChurchMember> members,
    Set<String> helperIds,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.groups_outlined),
          title: Text(
            l10n.cellDiscipleListTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(
            members.isEmpty
                ? l10n.cellDiscipleListEmpty
                : l10n.cellDiscipleListCount(members.length),
          ),
          children: [
            if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  l10n.cellDiscipleListEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...members.map((member) {
                final memberId = member.id;
                final isHelper =
                    memberId != null && helperIds.contains(memberId);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      member.fullName.isNotEmpty
                          ? member.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(
                    [
                      member.phone,
                      if (isHelper) l10n.cellHelpersBadge,
                    ].join(' · '),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _discipleActionsSection(
    AppLocalizations l10n, {
    required bool showAssignFab,
    required bool showRegisterFab,
  }) {
    if (!showAssignFab && !showRegisterFab) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showAssignFab) ...[
            FilledButton.icon(
              onPressed: _openAssignMembers,
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.cellDetailAssignDisciplesAction),
            ),
            if (showRegisterFab) const SizedBox(height: 12),
          ],
          if (showRegisterFab)
            FilledButton.icon(
              onPressed: _openRegisterMember,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.cellMemberRegisterNew),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cellId = _cell.id;
    final helperIds = _cell.helpers.map((helper) => helper.memberId).toSet();

    return StreamBuilder<List<ChurchMember>>(
      stream: cellId == null || cellId.isEmpty
          ? null
          : _memberService.watchMembersInCell(cellId),
      builder: (context, memberCountSnapshot) {
        final memberCount = memberCountSnapshot.data?.length ?? 0;
        final showRegisterFab = cellId != null &&
            cellId.isNotEmpty &&
            _permissions.canRegisterNewCellMember(
              _cell,
              currentMemberCount: memberCount,
              actingLeaderId: widget.actingLeaderId,
              supervisedLeaderIds: widget.supervisedLeaderIds,
            );
        final showAssignFab = cellId != null &&
            cellId.isNotEmpty &&
            _permissions.canAssignCellMembersFor(
              _cell,
              actingLeaderId: widget.actingLeaderId,
              supervisedLeaderIds: widget.supervisedLeaderIds,
            );

        return Scaffold(
      appBar: AppBar(
        title: Text(_cell.displayLabel),
        actions: [
          if (_permissions.canBlockCell && cellId != null && cellId.isNotEmpty)
            IconButton(
              icon: Icon(
                _cell.isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
              ),
              tooltip: _cell.isBlocked
                  ? l10n.cellsUnblockTitle
                  : l10n.cellsBlockTitle,
              onPressed: _blockingInProgress
                  ? null
                  : () => _toggleBlock(block: !_cell.isBlocked),
            ),
          if (_permissions.canEditCell &&
              !_cell.isBlocked &&
              cellId != null &&
              cellId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.commonEdit,
              onPressed: _openEdit,
            ),
        ],
      ),
      body: cellId == null || cellId.isEmpty
          ? Center(child: Text(l10n.cellDiscipleCellMissing))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_cell.isBlocked) _blockedBanner(l10n),
                if (_canClaimLeadership) _claimLeadershipBanner(l10n),
                _Section(title: l10n.cellRegSectionData, rows: _cellRows(l10n)),
                const SizedBox(height: 16),
                if (_permissions.canEditCell && !_cell.isBlocked) ...[
                  FilledButton.icon(
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.cellEditTitle),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_permissions.canBlockCell) ...[
                  OutlinedButton.icon(
                    onPressed: _blockingInProgress
                        ? null
                        : () => _toggleBlock(block: !_cell.isBlocked),
                    icon: Icon(
                      _cell.isBlocked
                          ? Icons.lock_open_outlined
                          : Icons.block_outlined,
                    ),
                    label: Text(
                      _cell.isBlocked
                          ? l10n.cellsUnblockTitle
                          : l10n.cellsBlockTitle,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                StreamBuilder<List<ChurchMember>>(
                  stream: _memberService.watchMembersInCell(cellId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_canRegisterAttendance && members.isNotEmpty) ...[
                          FilledButton.icon(
                            onPressed: _openRegisterAttendance,
                            icon: const Icon(Icons.event_available_outlined),
                            label: Text(l10n.cellAttendanceRegisterTitle),
                          ),
                          const SizedBox(height: 16),
                          _attendanceHistorySection(l10n, cellId),
                          const SizedBox(height: 16),
                        ],
                        _helpersSection(l10n, members),
                        _disciplesSection(l10n, members, helperIds),
                        if (!_cell.isBlocked)
                          _discipleActionsSection(
                            l10n,
                            showAssignFab: showAssignFab,
                            showRegisterFab: showRegisterFab,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
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
