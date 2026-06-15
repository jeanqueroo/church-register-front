import 'church_cell.dart';

class CellOverCapacityEntry {
  const CellOverCapacityEntry({
    required this.cell,
    required this.memberCount,
  });

  final ChurchCell cell;
  final int memberCount;
}
