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

  bool get canRegisterMember => isAdmin || isRegistrar;
  bool get canRegisterLeader => isAdmin || isRegistrar;
  bool get canViewMembersList => isAdmin;
  bool get canViewMembersByLeader => isAdmin;
  bool get canViewLeadersList => isAdmin;
  bool get canViewMyAssignedMembers => isAdmin || isLeader;
  bool get canViewLeaderNotifications => isLeader;
  bool get canManageAll => isAdmin;

  List<String> get roleLabels =>
      roles.map(AppUserRole.label).toList()..sort();
}
