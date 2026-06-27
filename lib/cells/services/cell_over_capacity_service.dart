import '../../members/services/member_service.dart';
import '../cell_member_capacity.dart';
import '../models/cell_over_capacity_entry.dart';
import '../models/church_cell.dart';
import 'cell_service.dart';

class CellOverCapacityService {
  CellOverCapacityService({
    CellService? cellService,
    MemberService? memberService,
  })  : _cellService = cellService ?? CellService(),
        _memberService = memberService ?? MemberService();

  final CellService _cellService;
  final MemberService _memberService;

  Future<List<CellOverCapacityEntry>> fetchForChurch(String churchId) async {
    if (churchId.isEmpty) return [];

    final cells = await _cellService.fetchCellsForChurch(churchId);
    final countsByCellId =
        await _memberService.fetchMemberCountsByCellForChurch(churchId);
    return buildOverCapacityEntries(
      cells: cells,
      countsByCellId: countsByCellId,
    );
  }

  /// Conteo efectivo: prioriza integrantes reales (`assignedCellId`) y usa
  /// `memberCount` del documento solo como respaldo.
  static int effectiveMemberCount({
    required ChurchCell cell,
    required Map<String, int> countsByCellId,
  }) {
    final cellId = cell.id?.trim();
    if (cellId != null && cellId.isNotEmpty) {
      final fromMembers = countsByCellId[cellId];
      if (fromMembers != null) return fromMembers;
    }
    return cell.memberCount ?? 0;
  }

  static List<CellOverCapacityEntry> buildOverCapacityEntries({
    required List<ChurchCell> cells,
    required Map<String, int> countsByCellId,
  }) {
    final entries = <CellOverCapacityEntry>[];

    for (final cell in cells) {
      final cellId = cell.id?.trim();
      if (cellId == null || cellId.isEmpty) continue;

      final memberCount = effectiveMemberCount(
        cell: cell,
        countsByCellId: countsByCellId,
      );
      if (memberCount > CellMemberCapacity.maxMembers) {
        entries.add(
          CellOverCapacityEntry(cell: cell, memberCount: memberCount),
        );
      }
    }

    entries.sort((a, b) {
      final byCount = b.memberCount.compareTo(a.memberCount);
      if (byCount != 0) return byCount;
      return a.cell.code.compareTo(b.cell.code);
    });

    return entries;
  }
}
