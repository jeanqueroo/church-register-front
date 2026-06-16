import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/leader_gender.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';
import '../cell_leader_gender.dart';
import '../cell_member_capacity.dart';
import '../models/church_cell.dart';
import 'register_cell_member_screen.dart';

class AssignCellMembersScreen extends StatefulWidget {
  const AssignCellMembersScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.memberService,
    this.permissions,
    this.actingLeaderId,
  });

  final ChurchCell cell;
  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions? permissions;
  /// `users.leaderId` del usuario que asigna (líder de la célula puede superar 12).
  final String? actingLeaderId;

  @override
  State<AssignCellMembersScreen> createState() =>
      _AssignCellMembersScreenState();
}

class _AssignCellMembersScreenState extends State<AssignCellMembersScreen> {
  MemberService get _memberService => widget.memberService ?? MemberService();

  AppPermissions get _permissions =>
      widget.permissions ?? AppPermissions.adminDefault();

  bool get _canAssign => _permissions.canAssignCellMembersFor(
        widget.cell,
        actingLeaderId: widget.actingLeaderId,
      );

  LeaderGender? _cellLeaderGender;
  bool _loadingLeaderGender = true;

  @override
  void initState() {
    super.initState();
    _loadCellLeaderGender();
  }

  Future<void> _loadCellLeaderGender() async {
    try {
      final gender = await fetchCellLeaderGender(widget.cell);
      if (!mounted) return;
      setState(() {
        _cellLeaderGender = gender;
        _loadingLeaderGender = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLeaderGender = false);
    }
  }

  bool get _canAssignByGender => _cellLeaderGender != null;

  Future<void> _openRegisterMember() async {
    final cellId = widget.cell.id;
    if (cellId == null || cellId.isEmpty) return;

    if (!_canAssignByGender) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cellMemberAssignLeaderGenderMissing),
        ),
      );
      return;
    }

    final count = await _memberService.countMembersInCell(cellId);
    if (!_permissions.canRegisterNewCellMember(
      widget.cell,
      currentMemberCount: count,
      actingLeaderId: widget.actingLeaderId,
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
          cell: widget.cell,
          registeredBy: widget.registeredBy,
          churchId: widget.cell.churchId ?? _permissions.churchId,
          memberService: widget.memberService,
          permissions: _permissions,
          actingLeaderId: widget.actingLeaderId,
        ),
      ),
    );
  }

  Future<void> _openSelectMember() async {
    final cellId = widget.cell.id;
    if (cellId == null || cellId.isEmpty) return;

    if (!_canAssignByGender) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cellMemberAssignLeaderGenderMissing),
        ),
      );
      return;
    }

    final count = await _memberService.countMembersInCell(cellId);
    final maxSelection = CellMemberCapacity.remainingAssignableSlots(
      currentCount: count,
      cell: widget.cell,
      actingLeaderId: widget.actingLeaderId,
    );

    if (maxSelection <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MemberService.messageForCellAssignmentLimit(context.l10n)),
        ),
      );
      return;
    }

    final selected = await Navigator.of(context).push<List<ChurchMember>>(
      MaterialPageRoute<List<ChurchMember>>(
        builder: (_) => SelectMemberForCellScreen(
          churchId: widget.cell.churchId ?? _permissions.churchId,
          memberService: widget.memberService,
          maxSelection: maxSelection,
          requiredGender: _cellLeaderGender,
        ),
      ),
    );
    if (selected == null || selected.isEmpty || !mounted) return;

    await _assignMembers(selected);
  }

  Future<void> _assignMembers(List<ChurchMember> members) async {
    final l10n = context.l10n;
    var assigned = 0;
    String? errorMessage;

    for (final member in members) {
      try {
        await _memberService.assignMemberToCell(
          member: member,
          cell: widget.cell,
          actingLeaderId: widget.actingLeaderId,
          requiredLeaderGender: _cellLeaderGender,
        );
        assigned++;
      } on CellAssignmentLimitException {
        errorMessage = MemberService.messageForCellAssignmentLimit(l10n);
        break;
      } on CellAssignmentGenderException {
        errorMessage = MemberService.messageForCellAssignmentGender(l10n);
        break;
      } on CellAssignmentLeaderException {
        errorMessage = MemberService.messageForCellAssignmentLeader(l10n);
        break;
      } on FirebaseException catch (e) {
        errorMessage = MemberService.messageFromFirestoreException(e, l10n);
        break;
      }
    }

    if (assigned > 0 &&
        assigned < members.length &&
        errorMessage == null) {
      errorMessage = l10n.cellMemberAssignLimitPartial(assigned, members.length);
    }

    if (!mounted) return;

    if (assigned > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assigned == 1
                ? l10n.cellMemberAssigned(members.first.fullName)
                : l10n.cellMemberAssignedMultiple(assigned),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _confirmUnassign(ChurchMember member) async {
    final l10n = context.l10n;
    final memberId = member.id;
    if (memberId == null || memberId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cellMemberUnassignTitle),
        content: Text(l10n.cellMemberUnassignConfirm(member.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cellMemberUnassignAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _memberService.unassignMemberFromCell(memberId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellMemberUnassigned(member.fullName))),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MemberService.messageFromFirestoreException(e, l10n),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cellId = widget.cell.id;

    return StreamBuilder<List<ChurchMember>>(
      stream: cellId == null || cellId.isEmpty
          ? null
          : _memberService.watchMembersInCell(cellId),
      builder: (context, memberCountSnapshot) {
        final memberCount = memberCountSnapshot.data?.length ?? 0;
        final showRegisterFab = cellId != null &&
            cellId.isNotEmpty &&
            _permissions.canRegisterNewCellMember(
              widget.cell,
              currentMemberCount: memberCount,
              actingLeaderId: widget.actingLeaderId,
            );

        return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellMemberAssignTitle),
      ),
      floatingActionButton: showRegisterFab
          ? FloatingActionButton.extended(
              onPressed: _openRegisterMember,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.cellMemberRegisterNew),
            )
          : null,
      body: cellId == null || cellId.isEmpty
          ? Center(child: Text(l10n.cellDiscipleCellMissing))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.cellMemberAssignHint(widget.cell.displayLabel),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loadingLeaderGender)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  )
                else if (_cellLeaderGender != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wc_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.cellMemberAssignGenderHint(
                                _cellLeaderGender!.localizedLabel(l10n),
                              ),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.cellMemberAssignLeaderGenderMissing,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_canAssign) ...[
                  FilledButton.icon(
                    onPressed: _canAssignByGender ? _openSelectMember : null,
                    icon: const Icon(Icons.person_add_outlined),
                    label: Text(l10n.cellMemberAssignAdd),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                      children: members.map((member) {
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
                            trailing: _canAssign
                                ? IconButton(
                                    icon: const Icon(Icons.link_off_outlined),
                                    tooltip: l10n.cellMemberUnassignAction,
                                    onPressed: () => _confirmUnassign(member),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
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

class SelectMemberForCellScreen extends StatefulWidget {
  const SelectMemberForCellScreen({
    super.key,
    this.churchId,
    this.memberService,
    this.maxSelection,
    this.requiredGender,
  });

  final String? churchId;
  final MemberService? memberService;
  /// Máximo seleccionable según cupo restante de la célula.
  final int? maxSelection;
  /// Solo integrantes del mismo sexo que el líder de la célula.
  final LeaderGender? requiredGender;

  @override
  State<SelectMemberForCellScreen> createState() =>
      _SelectMemberForCellScreenState();
}

class _SelectMemberForCellScreenState extends State<SelectMemberForCellScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedMemberIds = {};

  List<ChurchMember> _members = [];
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final service = widget.memberService ?? MemberService();
      final members = await service.fetchMembersWithoutCell(
        churchId: widget.churchId,
        matchingGender: widget.requiredGender,
      );
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  bool _matchesSearch(ChurchMember member, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      member.fullName,
      member.phone,
      member.assignedLeaderName,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  void _toggleMember(ChurchMember member, bool selected) {
    final id = member.id;
    if (id == null || id.isEmpty) return;

    final l10n = context.l10n;
    final maxSelection = widget.maxSelection;
    if (selected &&
        maxSelection != null &&
        _selectedMemberIds.length >= maxSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellMemberSelectMaxReached(maxSelection))),
      );
      return;
    }

    setState(() {
      if (selected) {
        _selectedMemberIds.add(id);
      } else {
        _selectedMemberIds.remove(id);
      }
    });
  }

  void _confirmSelection() {
    final selected = _members
        .where(
          (member) =>
              member.id != null && _selectedMemberIds.contains(member.id),
        )
        .toList();
    if (selected.isEmpty) return;
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _members
        .where((member) => _matchesSearch(member, _searchController.text))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellMemberSelectTitle),
      ),
      bottomNavigationBar: _selectedMemberIds.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _confirmSelection,
                  child: Text(
                    l10n.cellMemberSelectConfirm(_selectedMemberIds.length),
                  ),
                ),
              ),
            ),
      body: _buildBody(context, l10n, filtered),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<ChurchMember> filtered,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.cellMemberSelectLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadMembers,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.churchId == null || widget.churchId!.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.cellMemberSelectRequiresChurch,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.requiredGender != null
                ? l10n.cellMemberSelectEmptyGender(
                    widget.requiredGender!.localizedLabel(l10n),
                  )
                : l10n.cellMemberSelectEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.maxSelection != null
                          ? l10n.cellMemberSelectLimitHint(widget.maxSelection!)
                          : widget.requiredGender != null
                              ? l10n.cellMemberSelectGenderHint(
                                  widget.requiredGender!.localizedLabel(l10n),
                                )
                              : l10n.cellMemberSelectHint,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.cellMemberSelectSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(l10n.commonNoMatches))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final memberId = member.id;
                    if (memberId == null || memberId.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final subtitleParts = <String>[
                      member.phone,
                      if (member.assignedLeaderName != null &&
                          member.assignedLeaderName!.isNotEmpty)
                        l10n.membersListLeaderPrefix(member.assignedLeaderName!),
                    ];
                    final isSelected = _selectedMemberIds.contains(memberId);

                    return Card(
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) =>
                            _toggleMember(member, value ?? false),
                        secondary: CircleAvatar(
                          child: Text(
                            member.fullName.isNotEmpty
                                ? member.fullName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(member.fullName),
                        subtitle: Text(subtitleParts.join(' · ')),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
