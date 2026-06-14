import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/locale/weekday_labels.dart';
import '../../l10n/app_localizations.dart';
import '../../supervisors/services/supervisor_assignment_service.dart';
import '../models/church_cell.dart';
import '../services/cell_service.dart';
import 'cell_detail_screen.dart';
import 'register_cell_attendance_screen.dart';
import 'cell_attendance_overview_screen.dart';

enum MyAssignedCellsMode { browse, attendance, attendanceReport }

class MyAssignedCellsScreen extends StatefulWidget {
  const MyAssignedCellsScreen({
    super.key,
    required this.session,
    required this.registeredBy,
    this.cellService,
    this.supervisorAssignmentService,
    this.mode = MyAssignedCellsMode.browse,
  });

  final UserSession session;
  final String registeredBy;
  final CellService? cellService;
  final SupervisorAssignmentService? supervisorAssignmentService;
  final MyAssignedCellsMode mode;

  @override
  State<MyAssignedCellsScreen> createState() => _MyAssignedCellsScreenState();
}

class _MyAssignedCellsScreenState extends State<MyAssignedCellsScreen> {
  late final CellService _cellService;
  late final SupervisorAssignmentService _supervisorAssignmentService;

  List<ChurchCell> _cells = [];
  bool _loading = true;
  String? _loadError;
  bool _missingLeaderProfile = false;

  @override
  void initState() {
    super.initState();
    _cellService = widget.cellService ?? CellService();
    _supervisorAssignmentService =
        widget.supervisorAssignmentService ?? SupervisorAssignmentService();
    _loadCells();
  }

  Future<void> _loadCells() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _missingLeaderProfile = false;
    });

    try {
      final permissions = widget.session.permissions;
      final leaderIds = <String>{};
      final churchId = widget.session.profile.churchId;

      if (permissions.isLeader) {
        final ownLeaderId = widget.session.profile.leaderId?.trim();
        if (ownLeaderId == null || ownLeaderId.isEmpty) {
          if (!permissions.isSupervisor) {
            if (!mounted) return;
            setState(() {
              _cells = [];
              _loading = false;
              _missingLeaderProfile = true;
            });
            return;
          }
        } else {
          leaderIds.add(ownLeaderId);
        }
      }

      if (permissions.isSupervisor) {
        final supervisedIds = await _supervisorAssignmentService
            .fetchSupervisedLeaderIds(widget.session.uid);
        leaderIds.addAll(supervisedIds);
      }

      if (leaderIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cells = [];
          _loading = false;
        });
        return;
      }

      var cells = await _cellService.fetchCellsForLeaderIds(
        leaderIds: leaderIds.toList(),
        churchId: churchId,
      );

      if (widget.mode == MyAssignedCellsMode.attendance ||
          widget.mode == MyAssignedCellsMode.attendanceReport) {
        final ownLeaderId = widget.session.profile.leaderId?.trim();
        if (ownLeaderId != null && ownLeaderId.isNotEmpty) {
          cells = cells
              .where((cell) => cell.leaderId?.trim() == ownLeaderId)
              .toList();
        } else {
          cells = [];
        }
      }

      if (!mounted) return;
      setState(() {
        _cells = cells;
        _loading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = CellService.messageFromFirestoreException(e, context.l10n);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  void _openCellDetail(ChurchCell cell) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CellDetailScreen(
          cell: cell,
          registeredBy: widget.registeredBy,
          permissions: widget.session.permissions,
          cellService: widget.cellService,
          actingLeaderId: widget.session.profile.leaderId,
        ),
      ),
    );
  }

  void _openRegisterAttendance(ChurchCell cell) {
    final permissions = widget.session.permissions;
    if (!permissions.canRegisterCellAttendance(
      cell,
      actingLeaderId: widget.session.profile.leaderId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cellAttendanceDenied)),
      );
      return;
    }

    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterCellAttendanceScreen(
          cell: cell,
          registeredBy: widget.registeredBy,
          actingLeaderId: widget.session.profile.leaderId,
          permissions: permissions,
        ),
      ),
    );
  }

  void _openAttendanceReport(ChurchCell cell) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CellAttendanceOverviewScreen(
          cell: cell,
          registeredBy: widget.registeredBy,
          permissions: widget.session.permissions,
          actingLeaderId: widget.session.profile.leaderId,
        ),
      ),
    );
  }

  void _onCellTap(ChurchCell cell) {
    switch (widget.mode) {
      case MyAssignedCellsMode.attendance:
        _openRegisterAttendance(cell);
      case MyAssignedCellsMode.attendanceReport:
        _openAttendanceReport(cell);
      case MyAssignedCellsMode.browse:
        _openCellDetail(cell);
    }
  }

  String _screenTitle(AppLocalizations l10n) {
    return switch (widget.mode) {
      MyAssignedCellsMode.attendance => l10n.cellAttendancePickCellTitle,
      MyAssignedCellsMode.attendanceReport => l10n.cellAttendanceReportPickCellTitle,
      MyAssignedCellsMode.browse => l10n.myAssignedCellTitle,
    };
  }

  String _emptyMessage(AppLocalizations l10n) {
    return switch (widget.mode) {
      MyAssignedCellsMode.attendance => l10n.cellAttendanceNoOwnCell,
      MyAssignedCellsMode.attendanceReport => l10n.cellAttendanceReportNoOwnCell,
      MyAssignedCellsMode.browse => l10n.myAssignedCellEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final permissions = widget.session.permissions;

    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewMyAssignedCell,
      deniedMessage: l10n.myAssignedCellDenied,
      child: _buildContent(l10n, permissions),
    );
  }

  Widget _buildContent(AppLocalizations l10n, AppPermissions permissions) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_screenTitle(l10n))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_screenTitle(l10n))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.myAssignedCellLoadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadCells,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_missingLeaderProfile) {
      return Scaffold(
        appBar: AppBar(title: Text(_screenTitle(l10n))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.myAssignedCellNoLeaderProfile,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    if (_cells.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_screenTitle(l10n))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _emptyMessage(l10n),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    if (_cells.length == 1) {
      if (widget.mode == MyAssignedCellsMode.attendance) {
        return RegisterCellAttendanceScreen(
          cell: _cells.first,
          registeredBy: widget.registeredBy,
          permissions: permissions,
          actingLeaderId: widget.session.profile.leaderId,
        );
      }
      if (widget.mode == MyAssignedCellsMode.attendanceReport) {
        return CellAttendanceOverviewScreen(
          cell: _cells.first,
          registeredBy: widget.registeredBy,
          permissions: permissions,
          actingLeaderId: widget.session.profile.leaderId,
        );
      }
      return CellDetailScreen(
        cell: _cells.first,
        registeredBy: widget.registeredBy,
        permissions: permissions,
        cellService: widget.cellService,
        actingLeaderId: widget.session.profile.leaderId,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle(l10n))),
      body: RefreshIndicator(
        onRefresh: _loadCells,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _cells.length +
              (widget.mode == MyAssignedCellsMode.attendance ||
                      widget.mode == MyAssignedCellsMode.attendanceReport
                  ? 1
                  : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if ((widget.mode == MyAssignedCellsMode.attendance ||
                    widget.mode == MyAssignedCellsMode.attendanceReport) &&
                index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.mode == MyAssignedCellsMode.attendanceReport
                      ? l10n.cellAttendanceReportPickCellHint
                      : l10n.cellAttendancePickCellHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }

            final cellIndex = (widget.mode == MyAssignedCellsMode.attendance ||
                    widget.mode == MyAssignedCellsMode.attendanceReport)
                ? index - 1
                : index;
            final cell = _cells[cellIndex];
            final parts = <String>[
              if (cell.leaderName != null && cell.leaderName!.trim().isNotEmpty)
                l10n.myAssignedCellLeaderLabel(cell.leaderName!),
              if (cell.cellDay != null && cell.cellDay!.trim().isNotEmpty)
                '${l10n.cellRegMeetingDay}: ${localizedWeekday(l10n, cell.cellDay)}',
              if (cell.formattedAddress.isNotEmpty) cell.formattedAddress,
            ];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    cell.code.isNotEmpty ? cell.code[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(cell.displayLabel),
                subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onCellTap(cell),
              ),
            );
          },
        ),
      ),
    );
  }
}
