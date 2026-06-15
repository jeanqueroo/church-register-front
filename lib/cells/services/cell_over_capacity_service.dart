import '../../members/services/member_service.dart';
import '../cell_member_capacity.dart';
import '../models/cell_over_capacity_entry.dart';
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
    final entries = <CellOverCapacityEntry>[];

    for (final cell in cells) {
      final cellId = cell.id?.trim();
      if (cellId == null || cellId.isEmpty) continue;

      final memberCount = await _memberService.countMembersInCell(cellId);
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
