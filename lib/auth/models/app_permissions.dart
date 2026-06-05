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
  bool get canViewSupervisorLeaderAssignments =>
      isAdmin || isSupervisor || isSuperAdmin;
  bool get canAssignSupervisorLeaders => isAdmin || isSuperAdmin;
  bool get canViewMyAssignedMembers => isAdmin || isLeader;
  bool get canViewLeaderNotifications => isLeader;
  bool get canManageAll => isAdmin || isSuperAdmin;

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
