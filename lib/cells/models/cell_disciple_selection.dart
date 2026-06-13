import 'cell_disciple.dart';
import 'cell_disciple_draft.dart';

/// Discípulo agregado al registrar una célula (nuevo o sin célula asignada).
class CellDiscipleSelection {
  const CellDiscipleSelection({
    required this.draft,
    this.unassignedDiscipleId,
  });

  final CellDiscipleDraft draft;
  final String? unassignedDiscipleId;

  bool get isExisting =>
      unassignedDiscipleId != null && unassignedDiscipleId!.isNotEmpty;

  String get existingKey => unassignedDiscipleId ?? '';

  factory CellDiscipleSelection.newDisciple(CellDiscipleDraft draft) {
    return CellDiscipleSelection(draft: draft);
  }

  factory CellDiscipleSelection.existing({
    required CellDisciple disciple,
    required String discipleId,
  }) {
    return CellDiscipleSelection(
      draft: CellDiscipleDraft.fromDisciple(disciple),
      unassignedDiscipleId: discipleId,
    );
  }
}

/// Discípulo sin célula asignada (colección raíz `disciples`).
class ChurchDiscipleEntry {
  const ChurchDiscipleEntry({
    required this.disciple,
    required this.id,
  });

  final CellDisciple disciple;
  final String id;

  String get key => id;
}
