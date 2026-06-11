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
