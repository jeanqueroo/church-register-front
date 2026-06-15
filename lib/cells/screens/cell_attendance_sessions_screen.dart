import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../models/cell_attendance_session.dart';
import '../models/church_cell.dart';
import '../services/cell_attendance_service.dart';
import '../utils/cell_attendance_week_filter.dart';
import 'register_cell_attendance_screen.dart';

class CellAttendanceSessionsScreen extends StatefulWidget {
  const CellAttendanceSessionsScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.permissions,
    this.actingLeaderId,
    this.attendanceService,
  });

  final ChurchCell cell;
  final String registeredBy;
  final AppPermissions? permissions;
  final String? actingLeaderId;
  final CellAttendanceService? attendanceService;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<CellAttendanceSessionsScreen> createState() =>
      _CellAttendanceSessionsScreenState();
}

class _CellAttendanceSessionsScreenState
    extends State<CellAttendanceSessionsScreen> {
  late final CellAttendanceService _attendanceService;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _attendanceService = widget.attendanceService ?? CellAttendanceService();
    final (start, end) = lastNWeeksRange(4);
    _startDate = start;
    _endDate = endOfWeek(end);
  }

  bool get _canManage => widget._permissions.canManageCellAttendanceSessions(
        widget.cell,
        actingLeaderId: widget.actingLeaderId,
      );

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate != null && _startDate!.isAfter(_endDate!)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
      if (_startDate != null && _endDate!.isBefore(_startDate!)) {
        _startDate = _endDate;
      }
    });
  }

  Future<void> _openEdit(CellAttendanceSession session) async {
    if (!_canManage) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterCellAttendanceScreen(
          cell: widget.cell,
          registeredBy: widget.registeredBy,
          actingLeaderId: widget.actingLeaderId,
          sessionToEdit: session,
          permissions: widget._permissions,
          attendanceService: _attendanceService,
        ),
      ),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cellAttendanceUpdated)),
      );
    }
  }

  Future<void> _confirmDelete(CellAttendanceSession session) async {
    if (!_canManage) return;

    final l10n = context.l10n;
    final sessionId = session.id?.trim();
    final cellId = widget.cell.id?.trim();
    if (sessionId == null ||
        sessionId.isEmpty ||
        cellId == null ||
        cellId.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cellAttendanceDeleteTitle),
        content: Text(
          l10n.cellAttendanceDeleteConfirm(_formatDate(session.sessionDate)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cellAttendanceDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _attendanceService.deleteSession(
        cellId: cellId,
        sessionId: sessionId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellAttendanceDeleted)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CellAttendanceService.messageFromFirestoreException(e, l10n),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.memberSaveUnexpectedError)),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cell = widget.cell;
    final cellId = cell.id?.trim();

    return RoleGate(
      permissions: widget._permissions,
      allowed: _canManage,
      deniedMessage: l10n.cellAttendanceManageDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.cellAttendanceSessionsTitle),
        ),
        body: cellId == null || cellId.isEmpty
            ? Center(child: Text(l10n.cellDiscipleCellMissing))
            : Column(
                children: [
                  _DateRangeFilter(
                    l10n: l10n,
                    startDate: _startDate,
                    endDate: _endDate,
                    onPickStart: _pickStartDate,
                    onPickEnd: _pickEndDate,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        cell.displayLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<CellAttendanceSession>>(
                      stream: _attendanceService.watchSessions(cellId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final allSessions = snapshot.data ?? const [];
                        final filtered = filterSessionsByDateRange(
                          sessions: allSessions,
                          startDate: _startDate,
                          endDate: _endDate,
                        );

                        if (filtered.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.cellAttendanceSessionsEmpty,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final session = filtered[index];
                            return _SessionCard(
                              l10n: l10n,
                              session: session,
                              formatDate: _formatDate,
                              canManage: _canManage && !_deleting,
                              onEdit: () => _openEdit(session),
                              onDelete: () => _confirmDelete(session),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter({
    required this.l10n,
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final AppLocalizations l10n;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  String _format(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cellAttendanceSessionsDateRangeTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickStart,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(l10n.cellAttendanceSessionsFromDate(_format(startDate))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickEnd,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(l10n.cellAttendanceSessionsToDate(_format(endDate))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.l10n,
    required this.session,
    required this.formatDate,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final AppLocalizations l10n;
  final CellAttendanceSession session;
  final String Function(DateTime date) formatDate;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      '${l10n.cellAttendanceSessionTime}: ${session.sessionTime}',
      l10n.cellAttendancePresentCount(
        session.presentCount,
        session.totalCount,
      ),
    ];
    if (session.observations != null && session.observations!.trim().isNotEmpty) {
      subtitleParts.add(session.observations!.trim());
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(formatDate(session.sessionDate)),
        subtitle: Text(subtitleParts.join(' · ')),
        isThreeLine: subtitleParts.length > 2,
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.cellAttendanceEditAction),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        l10n.cellAttendanceDeleteAction,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            : null,
        onTap: canManage ? onEdit : null,
      ),
    );
  }
}
