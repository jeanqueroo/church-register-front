import '../notifications/services/cell_capacity_notification_service.dart';
import 'models/church_cell.dart';

class CellMemberCapacity {
  static int get maxMembers => CellCapacityNotificationService.capacityThreshold;

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

  static bool canAssignAnother({
    required int currentCount,
    required ChurchCell cell,
    required String? actingLeaderId,
  }) {
    return currentCount < maxMembers;
  }

  /// Registrar creyente nuevo superando el cupo: solo el líder de la célula.
  static bool canRegisterNewMemberWhenAtCapacity({
    required int currentCount,
    required ChurchCell cell,
    required String? actingLeaderId,
  }) {
    if (currentCount < maxMembers) return true;
    return isCellLeader(cell: cell, actingLeaderId: actingLeaderId);
  }

  /// Cupo restante para asignar integrantes a la célula.
  static int remainingAssignableSlots({
    required int currentCount,
    required ChurchCell cell,
    required String? actingLeaderId,
  }) {
    final remaining = maxMembers - currentCount;
    return remaining > 0 ? remaining : 0;
  }
}

class CellAssignmentLimitException implements Exception {}

class CellAssignmentLeaderOnlyException implements Exception {}

class CellAssignmentGenderException implements Exception {}
