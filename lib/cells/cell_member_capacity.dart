import '../notifications/services/cell_capacity_notification_service.dart';
import 'models/church_cell.dart';

class CellMemberCapacity {
  /// Umbral para alertas de capacidad y filtro «más de N discípulos».
  static int get maxMembers => CellCapacityNotificationService.capacityThreshold;

  /// Máximo de discípulos que puede tener una célula al asignar.
  static const int maxAssignableMembers = 23;

  static bool isCellLeader({
    required ChurchCell cell,
    required String? actingLeaderId,
  }) {
    final cellLeaderId = cell.leaderId?.trim();
    final actor = actingLeaderId?.trim();
    return cellLeaderId != null &&
        cellLeaderId.isNotEmpty &&
        actor != null &&
        actor == cellLeaderId;
  }

  static bool isSupervisedCellLeader({
    required ChurchCell cell,
    Iterable<String> supervisedLeaderIds = const [],
  }) {
    final cellLeaderId = cell.leaderId?.trim();
    if (cellLeaderId == null || cellLeaderId.isEmpty) return false;
    return supervisedLeaderIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .contains(cellLeaderId);
  }

  /// Líder titular de la célula o supervisor del líder de la célula.
  static bool canManageCellMembers({
    required ChurchCell cell,
    required String? actingLeaderId,
    Iterable<String> supervisedLeaderIds = const [],
  }) {
    return isCellLeader(cell: cell, actingLeaderId: actingLeaderId) ||
        isSupervisedCellLeader(
          cell: cell,
          supervisedLeaderIds: supervisedLeaderIds,
        );
  }

  static bool canAssignAnother({
    required int currentCount,
    required ChurchCell cell,
    required String? actingLeaderId,
  }) {
    return currentCount < maxAssignableMembers;
  }

  /// Registrar creyente nuevo superando el cupo de alerta (12): solo el líder de la célula.
  static bool canRegisterNewMemberWhenAtCapacity({
    required int currentCount,
    required ChurchCell cell,
    required String? actingLeaderId,
    Iterable<String> supervisedLeaderIds = const [],
  }) {
    if (currentCount >= maxAssignableMembers) return false;
    if (currentCount < maxMembers) return true;
    return canManageCellMembers(
      cell: cell,
      actingLeaderId: actingLeaderId,
      supervisedLeaderIds: supervisedLeaderIds,
    );
  }

  /// Cupo restante para asignar integrantes a la célula.
  static int remainingAssignableSlots({
    required int currentCount,
    required ChurchCell cell,
    required String? actingLeaderId,
  }) {
    final remaining = maxAssignableMembers - currentCount;
    return remaining > 0 ? remaining : 0;
  }
}

class CellAssignmentLimitException implements Exception {}

class CellAssignmentLeaderOnlyException implements Exception {}

class CellAssignmentGenderException implements Exception {}

class CellAssignmentLeaderException implements Exception {}
