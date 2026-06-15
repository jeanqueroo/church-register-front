import '../../cells/cell_member_capacity.dart';
import '../../cells/models/church_cell.dart';
import '../../l10n/app_localizations.dart';
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
  bool get canRegisterCell => isAdmin || isSuperAdmin;
  bool get canEditCell => isAdmin || isSuperAdmin;
  bool get canViewCells => isAdmin || isSuperAdmin;
  bool get canRegisterCellDisciple => isAdmin || isSuperAdmin;
  bool get canAssignCellMembers => isAdmin || isSuperAdmin;

  /// Registrar creyente nuevo en la célula (con cupo lleno solo el líder).
  bool canRegisterNewCellMember(
    ChurchCell cell, {
    required int currentMemberCount,
    String? actingLeaderId,
  }) {
    if (!canRegisterMember) return false;
    return CellMemberCapacity.canRegisterNewMemberWhenAtCapacity(
      currentCount: currentMemberCount,
      cell: cell,
      actingLeaderId: actingLeaderId,
    );
  }

  /// Admin/registrador o líder de la célula: asignar integrantes existentes.
  bool canAssignCellMembersFor(
    ChurchCell cell, {
    String? actingLeaderId,
  }) {
    if (canAssignCellMembers) return true;
    return CellMemberCapacity.isCellLeader(
      cell: cell,
      actingLeaderId: actingLeaderId,
    );
  }

  /// Líder asignado a la célula: registrar asistencia.
  bool canRegisterCellAttendance(
    ChurchCell cell, {
    String? actingLeaderId,
  }) {
    return CellMemberCapacity.isCellLeader(
      cell: cell,
      actingLeaderId: actingLeaderId,
    );
  }

  /// Ver y gestionar asistencias registradas (líder de célula o admin).
  bool canManageCellAttendanceSessions(ChurchCell cell, {String? actingLeaderId}) {
    if (isAdmin || isSuperAdmin) return true;
    return canRegisterCellAttendance(cell, actingLeaderId: actingLeaderId);
  }

  bool get canViewCellAttendanceSessionsMenu =>
      canViewMyAssignedCell || isAdmin || isSuperAdmin;

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
  bool get canViewBaptismCalendar =>
      isAdmin || isSupervisor || isLeader;
  bool get canRegisterBaptismCalendar => isAdmin;
  bool get canViewMembersList => isAdmin || isRegistrar || isSupervisor || isLeader;
  bool get canViewMembersByLeader => isAdmin;
  bool get canViewLeadersList => isAdmin;
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
  bool get canViewLeaderNotifications => isLeader;

  /// Registrar visitas a integrantes (todos los roles con acceso a creyentes).
  bool get canRegisterMemberVisits => canViewMembersList || isSuperAdmin;

  /// Ver historial de visitas (mismo alcance que registrar visitas).
  bool get canViewMemberVisits => canRegisterMemberVisits;

  /// Dashboard de visitas: supervisor (sus líderes), admin (iglesia), superadmin (todas).
  bool get canViewVisitsDashboard => isSupervisor || isAdmin || isSuperAdmin;

  /// Dashboard pastoral: mismo alcance que el de visitas.
  bool get canViewPastoralDashboard => canViewVisitsDashboard;
  bool get canManageAll => isAdmin || isSuperAdmin || isRegistrar;

  /// Crear, editar o eliminar creyentes (no aplica al rol líder).
  bool get canManageMembers => canManageAll;

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
