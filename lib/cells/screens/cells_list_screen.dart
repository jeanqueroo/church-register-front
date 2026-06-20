import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/locale/weekday_labels.dart';
import '../../l10n/app_localizations.dart';
import '../../members/services/member_service.dart';
import '../cell_member_capacity.dart';
import '../models/church_cell.dart';
import '../services/cell_service.dart';
import 'cell_detail_screen.dart';
import 'register_cell_disciple_screen.dart';
import 'register_cell_screen.dart';
import 'cell_attendance_overview_screen.dart';
import 'cell_attendance_sessions_screen.dart';

enum CellsListMode { browse, pickDisciple, attendanceReport, manageSessions }

class CellsListScreen extends StatelessWidget {
  const CellsListScreen({
    super.key,
    required this.registeredBy,
    this.cellService,
    this.permissions,
    this.mode = CellsListMode.browse,
  });

  final String registeredBy;
  final CellService? cellService;
  final AppPermissions? permissions;
  final CellsListMode mode;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  bool get _allowed => switch (mode) {
        CellsListMode.browse => _permissions.canViewCells,
        CellsListMode.pickDisciple => _permissions.canRegisterCellDisciple,
        CellsListMode.attendanceReport => _permissions.canViewCellAttendanceReport,
        CellsListMode.manageSessions => _permissions.canViewCellAttendanceSessionsMenu,
      };

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: _permissions,
      allowed: _allowed,
      deniedMessage: mode == CellsListMode.pickDisciple
          ? context.l10n.cellDiscipleDenied
          : mode == CellsListMode.attendanceReport
              ? context.l10n.cellAttendanceReportDenied
              : mode == CellsListMode.manageSessions
                  ? context.l10n.cellAttendanceManageDenied
                  : null,
      child: _CellsListBody(
        registeredBy: registeredBy,
        cellService: cellService,
        permissions: _permissions,
        mode: mode,
      ),
    );
  }
}

class _CellsListBody extends StatefulWidget {
  const _CellsListBody({
    required this.registeredBy,
    this.cellService,
    required this.permissions,
    required this.mode,
  });

  final String registeredBy;
  final CellService? cellService;
  final AppPermissions permissions;
  final CellsListMode mode;

  @override
  State<_CellsListBody> createState() => _CellsListBodyState();
}

class _CellsListBodyState extends State<_CellsListBody> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<ChurchCell> _cells = [];
  Map<String, int> _memberCountByCellId = {};
  bool _loading = true;
  bool _memberCountsLoaded = false;
  bool _loadingMemberCounts = false;
  bool _filterOverCapacity = false;
  Object? _loadError;
  StreamSubscription<List<ChurchCell>>? _cellsSubscription;
  final _memberService = MemberService();

  bool get _isBrowseMode => widget.mode == CellsListMode.browse;

  @override
  void initState() {
    super.initState();
    final service = widget.cellService ?? CellService();
    _cellsSubscription = service
        .watchCells(churchId: widget.permissions.churchId)
        .listen(
          (cells) {
            if (!mounted) return;
            setState(() {
              _cells = cells;
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

  bool get _cellsHaveStoredMemberCounts =>
      _cells.isNotEmpty && _cells.every((cell) => cell.memberCount != null);

  bool get _needsBulkMemberCounts =>
      _filterOverCapacity &&
      !_cellsHaveStoredMemberCounts &&
      !_memberCountsLoaded;

  Future<void> _loadMemberCountsIfNeeded() async {
    if (_cellsHaveStoredMemberCounts || _memberCountsLoaded || _loadingMemberCounts) {
      return;
    }

    setState(() => _loadingMemberCounts = true);
    try {
      final counts = await _memberService.fetchMemberCountsByCellForChurch(
        widget.permissions.churchId,
      );
      if (!mounted) return;
      setState(() {
        _memberCountByCellId = counts;
        _memberCountsLoaded = true;
        _loadingMemberCounts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMemberCounts = false);
    }
  }

  void _onOverCapacityFilterChanged(bool selected) {
    setState(() => _filterOverCapacity = selected);
    if (selected) {
      _loadMemberCountsIfNeeded();
    }
  }

  @override
  void dispose() {
    _cellsSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _matchesSearch(ChurchCell cell, String query, AppLocalizations l10n) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      cell.code,
      cell.name,
      cell.leaderName,
      cell.formattedAddress,
      localizedWeekday(l10n, cell.cellDay),
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  bool _isOverCapacity(ChurchCell cell) {
    final cellId = cell.id?.trim();
    if (cellId == null || cellId.isEmpty) return false;
    final count = _memberCountByCellId[cellId] ?? 0;
    return count > CellMemberCapacity.maxMembers;
  }

  int _memberCountFor(ChurchCell cell) {
    if (cell.memberCount != null) return cell.memberCount!;
    final cellId = cell.id?.trim();
    if (cellId == null || cellId.isEmpty) return 0;
    return _memberCountByCellId[cellId] ?? 0;
  }

  void _onCellTap(ChurchCell cell) {
    if (widget.mode == CellsListMode.pickDisciple) {
      Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => RegisterCellDiscipleScreen(
            cell: cell,
            registeredBy: widget.registeredBy,
            cellService: widget.cellService,
            permissions: widget.permissions,
          ),
        ),
      );
      return;
    }

    if (widget.mode == CellsListMode.attendanceReport) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CellAttendanceOverviewScreen(
            cell: cell,
            registeredBy: widget.registeredBy,
            permissions: widget.permissions,
          ),
        ),
      );
      return;
    }

    if (widget.mode == CellsListMode.manageSessions) {
      if (!widget.permissions.canManageCellAttendanceSessions(cell)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cellAttendanceManageDenied)),
        );
        return;
      }
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CellAttendanceSessionsScreen(
            cell: cell,
            registeredBy: widget.registeredBy,
            permissions: widget.permissions,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CellDetailScreen(
          cell: cell,
          registeredBy: widget.registeredBy,
          cellService: widget.cellService,
          permissions: widget.permissions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    var filtered = _cells
        .where((cell) => _matchesSearch(cell, _searchController.text, l10n))
        .toList();

    if (_filterOverCapacity) {
      filtered = filtered.where(_isOverCapacity).toList();
    }

    final pickingDisciple = widget.mode == CellsListMode.pickDisciple;
    final pickingAttendanceReport =
        widget.mode == CellsListMode.attendanceReport;
    final pickingManageSessions =
        widget.mode == CellsListMode.manageSessions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pickingDisciple
              ? l10n.cellDisciplePickCellTitle
              : pickingAttendanceReport
                  ? l10n.cellAttendanceReportPickCellTitle
                  : pickingManageSessions
                      ? l10n.cellAttendanceSessionsPickCellTitle
                      : l10n.cellsListTitle,
        ),
      ),
      floatingActionButton: !pickingDisciple &&
              !pickingAttendanceReport &&
              !pickingManageSessions &&
              widget.permissions.canRegisterCell
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => RegisterCellScreen(
                      registeredBy: widget.registeredBy,
                      churchId: widget.permissions.churchId,
                      cellService: widget.cellService,
                      permissions: widget.permissions,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.menuNewCell),
            )
          : null,
      body: _buildBody(context, l10n, filtered),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<ChurchCell> filtered,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.cellsListLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_cells.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.cellsListEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final pickingDisciple = widget.mode == CellsListMode.pickDisciple;
    final pickingAttendanceReport =
        widget.mode == CellsListMode.attendanceReport;
    final pickingManageSessions =
        widget.mode == CellsListMode.manageSessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pickingDisciple)
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
                        l10n.cellDisciplePickCellHint,
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
          ),
        if (pickingAttendanceReport)
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
                        l10n.cellAttendanceReportPickCellHint,
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
          ),
        if (pickingManageSessions)
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
                        l10n.cellAttendanceSessionsPickCellHint,
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
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            key: const ValueKey('cells_list_search'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.cellsListSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (_isBrowseMode) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(
                  l10n.cellsListFilterOverCapacity(CellMemberCapacity.maxMembers),
                ),
                selected: _filterOverCapacity,
                onSelected: _loadingMemberCounts
                    ? null
                    : _onOverCapacityFilterChanged,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _needsBulkMemberCounts && _loadingMemberCounts
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? Center(child: Text(l10n.commonNoMatches))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cell = filtered[index];
                    final memberCount = _memberCountFor(cell);
                    final parts = <String>[
                      if (_filterOverCapacity)
                        l10n.cellsListMemberCount(memberCount),
                      if (cell.cellDay != null)
                        localizedWeekday(l10n, cell.cellDay!) ?? cell.cellDay!,
                      if (cell.leaderName != null) cell.leaderName!,
                      if (cell.formattedAddress.isNotEmpty)
                        cell.formattedAddress,
                    ];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            cell.code.isNotEmpty
                                ? cell.code[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(cell.displayLabel),
                        subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
                        trailing: Icon(
                          pickingDisciple
                              ? Icons.person_add_outlined
                              : pickingAttendanceReport
                                  ? Icons.fact_check_outlined
                                  : pickingManageSessions
                                      ? Icons.history_outlined
                                      : Icons.chevron_right,
                        ),
                        onTap: () => _onCellTap(cell),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
