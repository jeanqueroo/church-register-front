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

  bool get isSuperAdmin => roles.contains(AppUserRole.superAdmin);

  /// Administrador de una iglesia (`churchId` en Firestore).
  bool get isAdmin => roles.contains(AppUserRole.admin);

  bool get isRegistrar => roles.contains(AppUserRole.registrar);
  bool get isSupervisor => roles.contains(AppUserRole.supervisor);
  bool get isLeader => roles.contains(AppUserRole.leader);

  bool get canRegisterMember => isAdmin || isRegistrar || isSuperAdmin;
  bool get canRegisterLeader => isAdmin || isSuperAdmin;
  bool get canViewMembersList => isAdmin || isSuperAdmin;
  bool get canViewMembersByLeader => isAdmin || isSuperAdmin;
  bool get canViewLeadersList => isAdmin || isSuperAdmin;
  /// Admin sin rol supervisor: asignar líderes a supervisores.
  bool get canAssignSupervisorLeaders =>
      (isAdmin || isSuperAdmin) && !isSupervisor;

  /// Alias de [canAssignSupervisorLeaders] para el menú de asignación.
  bool get canViewSupervisorLeaderAssignments => canAssignSupervisorLeaders;

  /// Supervisor: ver sus líderes asignados (solo lectura).
  bool get canViewMySupervisedLeaders => isSupervisor;

  /// Supervisor: ver creyentes asignados a sus líderes (solo lectura).
  bool get canViewSupervisedLeaderMembers => isSupervisor;
  bool get canViewMyAssignedMembers => isLeader;
  bool get canViewLeaderNotifications => isLeader;

  /// Líder: registrar visitas a sus integrantes asignados.
  bool get canRegisterMemberVisits => isLeader;

  /// Ver historial de visitas (líder, admin, supervisor de ese líder).
  bool get canViewMemberVisits =>
      isLeader || canManageMembers || canViewSupervisedLeaderMembers;

  /// Dashboard de visitas: supervisor (sus líderes), admin (iglesia), superadmin (todas).
  bool get canViewVisitsDashboard => isSupervisor || isAdmin || isSuperAdmin;

  /// Dashboard pastoral: mismo alcance que el de visitas.
  bool get canViewPastoralDashboard => canViewVisitsDashboard;
  bool get canManageAll => isAdmin || isSuperAdmin;

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

  List<String> get roleLabels =>
      roles.map(AppUserRole.label).toList()..sort();
}
