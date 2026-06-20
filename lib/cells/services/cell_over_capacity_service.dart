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
    return buildOverCapacityEntries(
      cells: cells,
      countsByCellId: await _resolveCountsByCellId(
        churchId: churchId,
        cells: cells,
      ),
    );
  }

  static List<CellOverCapacityEntry> buildOverCapacityEntries({
    required List<ChurchCell> cells,
    required Map<String, int> countsByCellId,
  }) {
    final entries = <CellOverCapacityEntry>[];

    for (final cell in cells) {
      final cellId = cell.id?.trim();
      if (cellId == null || cellId.isEmpty) continue;

      final memberCount = cell.memberCount ?? countsByCellId[cellId] ?? 0;
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

  Future<Map<String, int>> _resolveCountsByCellId({
    required String churchId,
    required List<ChurchCell> cells,
  }) async {
    final needsBulkCounts = cells.any((cell) => cell.memberCount == null);
    if (!needsBulkCounts) return const {};

    return _memberService.fetchMemberCountsByCellForChurch(churchId);
  }
}
