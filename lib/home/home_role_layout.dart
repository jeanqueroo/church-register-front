import '../auth/models/app_permissions.dart';

enum HomeRoleLayout {
  leader,
  supervisor,
  registrar,
  admin,
  superAdmin,
}

HomeRoleLayout resolveHomeRoleLayout(AppPermissions permissions) {
  if (permissions.isSuperAdmin &&
      !permissions.isAdmin &&
      !permissions.isRegistrar &&
      !permissions.isSupervisor &&
      !permissions.isLeader) {
    return HomeRoleLayout.superAdmin;
  }
  if (permissions.isAdmin) return HomeRoleLayout.admin;
  if (permissions.isRegistrar &&
      !permissions.isSupervisor &&
      !permissions.isLeader) {
    return HomeRoleLayout.registrar;
  }
  if (permissions.isSupervisor) return HomeRoleLayout.supervisor;
  if (permissions.isLeader) return HomeRoleLayout.leader;
  if (permissions.isRegistrar) return HomeRoleLayout.registrar;
  if (permissions.isSuperAdmin) return HomeRoleLayout.superAdmin;
  return HomeRoleLayout.admin;
}
