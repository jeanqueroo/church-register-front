import '../../cells/cell_member_capacity.dart';
import '../../cells/models/church_cell.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import 'app_user_role.dart';

/// Permisos efectivos según los roles del usuario (unión de varios roles).
class AppPermissions {
  AppPermissions(this.roles, {this.churchId});

  final Set<String> roles;
  final String? churchId;

  factory AppPermissions.fromRoles(
    List<String> roles, {
    String? churchId,
  }) {
    return AppPermissions(roles.toSet(), churchId: churchId);
  }

  /// Sin perfil en Firestore: super administrador (cuenta de Firebase Console).
  factory AppPermissions.superAdminDefault() {
    return AppPermissions({AppUserRole.superAdmin});
  }

  /// Compatibilidad con pantallas que asumían admin por defecto.
  factory AppPermissions.adminDefault() => AppPermissions.superAdminDefault();

  /// Coincide con `isSuperAdmin()` en Firestore: rol `superadmin` o sin roles.
  bool get isSuperAdmin =>
      roles.isEmpty || roles.contains(AppUserRole.superAdmin);

  /// Administrador de una iglesia (`churchId` en Firestore).
  bool get isAdmin => roles.contains(AppUserRole.admin);

  bool get isRegistrar => roles.contains(AppUserRole.registrar);
  bool get isSupervisor => roles.contains(AppUserRole.supervisor);
  bool get isLeader => roles.contains(AppUserRole.leader);

  bool get canRegisterMember => isAdmin || isRegistrar || isSupervisor || isLeader;
  bool get canRegisterLeader => isAdmin;
  bool get canViewLeaderMenu => isAdmin;
  bool get canViewLeaderDashboard => isAdmin;
  bool get canRegisterCell => isAdmin;
  bool get canEditCell => isAdmin;
  /// Bloquear / desbloquear célula (administrador de iglesia).
  bool get canBlockCell => isAdmin;

  /// Líder/supervisor: asignarse como titular si la célula aún no tiene líder.
  bool canClaimOwnCellLeadership(
    ChurchCell cell, {
    String? actingLeaderId,
  }) {
    if (cell.isBlocked) return false;
    if (canEditCell) return false;
    final actor = actingLeaderId?.trim();
    if (actor == null || actor.isEmpty) return false;
    if (!isLeader && !isSupervisor) return false;
    final currentLeaderId = cell.leaderId?.trim();
    return currentLeaderId == null || currentLeaderId.isEmpty;
  }

  bool get canViewCells => isAdmin;
  bool get canViewCellDashboard => isAdmin;
  bool get canRegisterCellDisciple => isAdmin;
  bool get canAssignCellMembers => isAdmin;

  /// Registrar creyente nuevo en la célula (con cupo lleno solo el líder).
  bool canRegisterNewCellMember(
    ChurchCell cell, {
    required int currentMemberCount,
    String? actingLeaderId,
    Iterable<String> supervisedLeaderIds = const [],
  }) {
    if (cell.isBlocked) return false;
    if (!canRegisterMember) return false;
    return CellMemberCapacity.canRegisterNewMemberWhenAtCapacity(
      currentCount: currentMemberCount,
      cell: cell,
      actingLeaderId: actingLeaderId,
      supervisedLeaderIds: supervisedLeaderIds,
    );
  }

  /// Admin/registrador, líder de la célula o supervisor de su líder.
  bool canAssignCellMembersFor(
    ChurchCell cell, {
    String? actingLeaderId,
    Iterable<String> supervisedLeaderIds = const [],
  }) {
    if (cell.isBlocked) return false;
    if (canAssignCellMembers) return true;
    return CellMemberCapacity.canManageCellMembers(
      cell: cell,
      actingLeaderId: actingLeaderId,
      supervisedLeaderIds: supervisedLeaderIds,
    );
  }

  /// Líder asignado a la célula: registrar asistencia.
  bool canRegisterCellAttendance(
    ChurchCell cell, {
    String? actingLeaderId,
  }) {
    if (cell.isBlocked) return false;
    return CellMemberCapacity.isCellLeader(
      cell: cell,
      actingLeaderId: actingLeaderId,
    );
  }

  /// Ver y gestionar asistencias registradas (líder de la célula).
  bool canManageCellAttendanceSessions(ChurchCell cell, {String? actingLeaderId}) {
    return canRegisterCellAttendance(cell, actingLeaderId: actingLeaderId);
  }

  bool get canViewCellAttendanceSessionsMenu => canViewMyAssignedCell;

  /// Asignar ayudantes de célula (máx. 3): admin/registrador o líder de la célula.
  bool canManageCellHelpers(String? cellLeaderId, {String? actingLeaderId}) {
    if (canEditCell) return true;
    final leaderId = cellLeaderId?.trim();
    final actorId = actingLeaderId?.trim();
    return (isLeader || isSupervisor) &&
        leaderId != null &&
        leaderId.isNotEmpty &&
        actorId != null &&
        actorId == leaderId;
  }

  bool canManageHelpersForCell(ChurchCell cell, {String? actingLeaderId}) {
    if (cell.isBlocked) return false;
    return canManageCellHelpers(
      cell.leaderId,
      actingLeaderId: actingLeaderId,
    );
  }

  bool get canViewBaptismCalendar =>
      isAdmin || isSupervisor || isLeader;
  /// Solo el administrador de iglesia puede crear o eliminar fechas de bautismo.
  bool get canRegisterBaptismCalendar => isAdmin;

  /// Confirmar bautizados en fechas pasadas (solo administrador de iglesia).
  bool get canConfirmBaptismMembers => isAdmin;

  /// Estadísticas de bautismos (administrador / super administrador).
  bool get canViewBaptismDashboard => isAdmin;

  /// Asignar integrantes a una fecha de bautismo (admin, supervisor o líder).
  bool get canAssignBaptismCalendarMembers => canViewBaptismCalendar;
  bool get canViewMembersList => isAdmin || isRegistrar || isSupervisor || isLeader;
  bool get canViewOldMembersList => isAdmin;
  bool get canViewMembersByLeader => isAdmin;
  bool get canViewLeadersList => isAdmin;
  /// Descargar listados en Excel (solo administrador de iglesia).
  bool get canExportExcel => isAdmin;
  /// Admin sin rol supervisor: asignar líderes a supervisores.
  bool get canAssignSupervisorLeaders =>
      (isAdmin) && !isSupervisor;

  /// Alias de [canAssignSupervisorLeaders] para el menú de asignación.
  bool get canViewSupervisorLeaderAssignments => canAssignSupervisorLeaders;

  /// Supervisor: ver sus líderes asignados (solo lectura).
  bool get canViewMySupervisedLeaders => isSupervisor;

  /// Supervisor: ver creyentes asignados a sus líderes (solo lectura).
  bool get canViewSupervisedLeaderMembers => isSupervisor;
  bool get canViewMyAssignedMembers => isLeader;
  /// Célula propia (como líder de célula): líderes y supervisores con célula asignada.
  bool get canViewMyAssignedCell => isLeader || isSupervisor;

  /// Resumen de asistencia por integrante (líder / supervisor / admin).
  bool get canViewCellAttendanceReport => canViewCells || canViewMyAssignedCell;

  /// Inasistencias críticas por líder (solo administrador de iglesia).
  bool get canViewCellAbsenceByLeader => isAdmin;
  bool get canViewChurchNotifications =>
      isAdmin && churchId != null && churchId!.trim().isNotEmpty;
  /// Campana de asignaciones pastorales (líder y supervisor con ficha de líder).
  bool get canViewLeaderNotifications => isLeader || isSupervisor;

  /// Registrar visitas a integrantes (todos los roles con acceso a creyentes).
  bool get canRegisterMemberVisits => canViewMembersList || isSuperAdmin;

  /// Ver historial de visitas (mismo alcance que registrar visitas).
  bool get canViewMemberVisits => canRegisterMemberVisits;

  /// Dashboard de visitas: supervisor (sus líderes), admin (iglesia), superadmin (todas).
  bool get canViewVisitsDashboard => isSupervisor || isAdmin || isSuperAdmin;

  /// Dashboard pastoral: mismo alcance que el de visitas.
  bool get canViewPastoralDashboard => canViewVisitsDashboard;
  bool get canManageAll => isAdmin || isSuperAdmin || isRegistrar;

  /// Crear, editar o eliminar creyentes (admin, superadmin, registrador).
  bool get canManageMembers => canManageAll;

  /// Editar un creyente: gestión completa o nuevo creyente (líder/supervisor/registrador).
  bool canEditMember(ChurchMember member) {
    if (canManageMembers) return true;
    if (!member.isNewBeliever) return false;
    return isLeader || isSupervisor || isRegistrar;
  }

  /// Pasar un nuevo creyente a miembro (deja de figurar en nuevos creyentes).
  bool canPromoteNewBelieverToMember(ChurchMember member) {
    if (!member.isNewBeliever) return false;
    return canManageMembers || canEditMember(member);
  }

  /// Editar discípulo de una célula: quien puede gestionar miembros de esa célula.
  bool canEditCellDisciple(
    ChurchMember member,
    ChurchCell cell, {
    String? actingLeaderId,
    Iterable<String> supervisedLeaderIds = const [],
  }) {
    if (canEditMember(member)) return true;
    final cellId = cell.id?.trim();
    final memberCellId = member.assignedCellId?.trim();
    if (cellId == null ||
        cellId.isEmpty ||
        memberCellId == null ||
        memberCellId.isEmpty ||
        memberCellId != cellId) {
      return false;
    }
    return canAssignCellMembersFor(
      cell,
      actingLeaderId: actingLeaderId,
      supervisedLeaderIds: supervisedLeaderIds,
    );
  }

  /// Ver datos de la iglesia en Mi cuenta (solo lectura).
  bool get canViewChurchData =>
      churchId != null && churchId!.trim().isNotEmpty;

  /// Solo super administrador: iglesias y administradores de plataforma.
  bool get canViewChurchesList => isSuperAdmin;
  bool get canCreateChurch => isSuperAdmin;
  bool get canEditAnyChurch => isSuperAdmin;
  bool get canBlockChurch => isSuperAdmin;
  bool get canRegisterAdmin => isSuperAdmin;
  bool get canViewAdminsList => isSuperAdmin;
  bool get canEditAdmin => isSuperAdmin;
  bool get canBlockAdmin => isSuperAdmin;

  List<String> roleLabelsFor(AppLocalizations l10n) =>
      roles.map((role) => AppUserRole.localizedLabel(role, l10n)).toList()
        ..sort();

  List<String> get roleLabels =>
      roles.map(AppUserRole.label).toList()..sort();
}
