import '../models/cell_member_attendance_summary.dart';
import '../models/church_cell.dart';
import '../models/leader_absence_list_item.dart';
import '../models/leader_cell_absence_report.dart';
import '../utils/cell_attendance_summary_builder.dart';
import 'cell_attendance_service.dart';
import 'cell_service.dart';

class CellAbsenceByLeaderService {
  CellAbsenceByLeaderService({
    CellService? cellService,
    CellAttendanceService? attendanceService,
  })  : _cellService = cellService ?? CellService(),
        _attendanceService = attendanceService ?? CellAttendanceService();

  static const minConsecutiveAbsences =
      CellMemberAbsenceAlert.criticalAbsenceThreshold;

  /// Con umbral 3, pocas sesiones recientes bastan y reducen lecturas.
  static const recentSessionsLimit = 8;

  final CellService _cellService;
  final CellAttendanceService _attendanceService;

  /// Solo células/líderes: una consulta rápida.
  Future<List<LeaderAbsenceListItem>> loadLeadersForChurch(
    String churchId,
  ) async {
    if (churchId.trim().isEmpty) return [];

    final cells = await _cellService.fetchCellsForChurch(churchId);
    if (cells.isEmpty) return [];

    final byLeader = <String, _LeaderCellsBuilder>{};
    for (final cell in cells) {
      final leaderId = cell.leaderId?.trim();
      final cellId = cell.id?.trim();
      if (leaderId == null ||
          leaderId.isEmpty ||
          cellId == null ||
          cellId.isEmpty) {
        continue;
      }
      final builder = byLeader.putIfAbsent(
        leaderId,
        () => _LeaderCellsBuilder(
          leaderId: leaderId,
          leaderName: _leaderLabel(cell),
        ),
      );
      builder.addCell(cell);
    }

    final leaders = byLeader.values.map((b) => b.build()).toList()
      ..sort((a, b) => a.leaderName.compareTo(b.leaderName));
    return leaders;
  }

  /// Inasistencias del líder: solo lee sesiones (sin members).
  Future<List<LeaderCellAbsenceReport>> loadReportsForLeader({
    required String leaderId,
    required List<ChurchCell> cells,
  }) async {
    final id = leaderId.trim();
    if (id.isEmpty || cells.isEmpty) return [];

    final reports = await Future.wait(
      cells.map((cell) => _buildReportForCell(cell: cell, leaderId: id)),
    );

    final result = reports.whereType<LeaderCellAbsenceReport>().toList();
    result.sort((a, b) {
      final byCritical = b.criticalCount.compareTo(a.criticalCount);
      if (byCritical != 0) return byCritical;
      return a.cellCode.compareTo(b.cellCode);
    });
    return result;
  }

  Future<List<LeaderCellAbsenceReport>> loadForChurch(String churchId) async {
    final leaders = await loadLeadersForChurch(churchId);
    if (leaders.isEmpty) return [];

    final nested = await Future.wait(
      leaders.map(
        (leader) => loadReportsForLeader(
          leaderId: leader.leaderId,
          cells: leader.cells,
        ),
      ),
    );

    final result = nested.expand((reports) => reports).toList();
    result.sort((a, b) {
      final byCritical = b.criticalCount.compareTo(a.criticalCount);
      if (byCritical != 0) return byCritical;
      return a.leaderName.compareTo(b.leaderName);
    });
    return result;
  }

  Future<LeaderCellAbsenceReport?> _buildReportForCell({
    required ChurchCell cell,
    required String leaderId,
  }) async {
    final cellId = cell.id?.trim();
    if (cellId == null || cellId.isEmpty) return null;

    final sessions = await _attendanceService.fetchSessions(
      cellId,
      limit: recentSessionsLimit,
    );
    final critical = buildCriticalAbsencesFromSessions(
      sessions: sessions,
      minConsecutiveAbsences: minConsecutiveAbsences,
    );

    return LeaderCellAbsenceReport(
      leaderId: leaderId,
      leaderName: _leaderLabel(cell),
      cellCode: cell.code,
      cellId: cellId,
      totalDisciples: critical.length,
      criticalDisciples: critical,
    );
  }

  String _leaderLabel(ChurchCell cell) {
    final name = cell.leaderName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final leaderId = cell.leaderId?.trim();
    if (leaderId != null && leaderId.isNotEmpty) return leaderId;
    return cell.code;
  }
}

class _LeaderCellsBuilder {
  _LeaderCellsBuilder({
    required this.leaderId,
    required String leaderName,
  }) : _leaderName = leaderName;

  final String leaderId;
  String _leaderName;
  final List<ChurchCell> _cells = [];

  void addCell(ChurchCell cell) {
    _cells.add(cell);
    final incoming = cell.leaderName?.trim();
    if ((_leaderName.isEmpty || _leaderName == leaderId) &&
        incoming != null &&
        incoming.isNotEmpty) {
      _leaderName = incoming;
    }
  }

  LeaderAbsenceListItem build() {
    _cells.sort((a, b) => a.code.compareTo(b.code));
    return LeaderAbsenceListItem(
      leaderId: leaderId,
      leaderName: _leaderName,
      cells: List.unmodifiable(_cells),
    );
  }
}
