import 'app_user_role.dart';

/// Permisos efectivos según los roles del usuario (unión de varios roles).
class AppPermissions {
  AppPermissions(this.roles);

  final Set<String> roles;

  factory AppPermissions.fromRoles(List<String> roles) {
    return AppPermissions(roles.toSet());
  }

  /// Sin perfil en Firestore: administrador (usuarios creados en Console).
  factory AppPermissions.adminDefault() {
    return AppPermissions({AppUserRole.admin});
  }

  bool get isAdmin => roles.contains(AppUserRole.admin);
  bool get isRegistrar => roles.contains(AppUserRole.registrar);
  bool get isLeader => roles.contains(AppUserRole.leader);
  bool get isSupervisor => roles.contains(AppUserRole.supervisor);

  /// Pantalla principal con lista y mapa de creyentes de sus líderes.
  bool get usesSupervisorHome => isSupervisor && !isAdmin;

  bool get canRegisterMember => isAdmin || isRegistrar || isSupervisor;
  bool get canRegisterLeader => isAdmin || isSupervisor;
  bool get canViewMembersList => isAdmin || isRegistrar || isSupervisor;
  bool get canViewMembersByLeader => isAdmin || isSupervisor;
  bool get canViewLeadersList => isAdmin || isSupervisor;
  bool get canViewSupervisorLeaderAssignments => isAdmin || isSupervisor;
  bool get canAssignSupervisorLeaders => isAdmin;
  bool get canViewMyAssignedMembers => isAdmin || isLeader;
  bool get canViewLeaderNotifications => isLeader;
  bool get canManageAll => isAdmin;

  List<String> get roleLabels =>
      roles.map(AppUserRole.label).toList()..sort();
}
