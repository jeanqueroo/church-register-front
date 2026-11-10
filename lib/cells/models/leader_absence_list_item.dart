import 'church_cell.dart';

/// Líder con células asignadas (listado rápido, sin calcular inasistencias).
class LeaderAbsenceListItem {
  const LeaderAbsenceListItem({
    required this.leaderId,
    required this.leaderName,
    required this.cells,
  });

  final String leaderId;
  final String leaderName;
  final List<ChurchCell> cells;
}
