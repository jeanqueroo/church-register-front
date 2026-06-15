import '../../members/services/member_service.dart';
import '../models/cell_member_attendance_summary.dart';
import '../models/church_cell.dart';
import '../models/leader_cell_absence_report.dart';
import '../utils/cell_attendance_summary_builder.dart';
import 'cell_attendance_service.dart';
import 'cell_service.dart';

class CellAbsenceByLeaderService {
  CellAbsenceByLeaderService({
    CellService? cellService,
    MemberService? memberService,
    CellAttendanceService? attendanceService,
  })  : _cellService = cellService ?? CellService(),
        _memberService = memberService ?? MemberService(),
        _attendanceService = attendanceService ?? CellAttendanceService();

  static const minConsecutiveAbsences =
      CellMemberAbsenceAlert.criticalAbsenceThreshold;

  final CellService _cellService;
  final MemberService _memberService;
  final CellAttendanceService _attendanceService;

  Future<List<LeaderCellAbsenceReport>> loadForChurch(String churchId) async {
    if (churchId.trim().isEmpty) return [];

    final cells = await _cellService.fetchCellsForChurch(churchId);
    if (cells.isEmpty) return [];

    final reports = await Future.wait(
      cells.map((cell) async {
        final cellId = cell.id?.trim();
        final leaderId = cell.leaderId?.trim();
        if (cellId == null ||
            cellId.isEmpty ||
            leaderId == null ||
            leaderId.isEmpty) {
          return null;
        }

        final members = await _memberService.fetchMembersInCell(cellId);
        if (members.isEmpty) {
          return LeaderCellAbsenceReport(
            leaderId: leaderId,
            leaderName: _leaderLabel(cell),
            cellCode: cell.code,
            cellId: cellId,
            totalDisciples: 0,
            criticalDisciples: const [],
          );
        }

        final sessions = await _attendanceService.fetchSessions(cellId);
        final summaries = buildCellMemberAttendanceSummaries(
          members: members,
          sessions: sessions,
        );
        final critical = summaries
            .where(
              (summary) =>
                  summary.consecutiveAbsenceStreak >= minConsecutiveAbsences,
            )
            .toList();

        return LeaderCellAbsenceReport(
          leaderId: leaderId,
          leaderName: _leaderLabel(cell),
          cellCode: cell.code,
          cellId: cellId,
          totalDisciples: members.length,
          criticalDisciples: critical,
        );
      }),
    );

    final result = reports.whereType<LeaderCellAbsenceReport>().toList();
    result.sort((a, b) {
      final byCritical = b.criticalCount.compareTo(a.criticalCount);
      if (byCritical != 0) return byCritical;
      return a.leaderName.compareTo(b.leaderName);
    });
    return result;
  }

  String _leaderLabel(ChurchCell cell) {
    final name = cell.leaderName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final leaderId = cell.leaderId?.trim();
    if (leaderId != null && leaderId.isNotEmpty) return leaderId;
    return cell.code;
  }
}
