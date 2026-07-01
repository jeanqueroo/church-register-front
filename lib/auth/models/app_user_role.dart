import '../../l10n/app_localizations.dart';

/// Identificadores de rol en Firestore (`users.roles`).
class AppUserRole {
  AppUserRole._();

  static const String superAdmin = 'superadmin';
  static const String admin = 'admin';
  static const String registrar = 'registrador';
  static const String supervisor = 'supervisor';
  static const String leader = 'leader';

  static const all = [superAdmin, admin, registrar, supervisor, leader];

  /// Roles que un administrador puede asignar al registrar un líder.
  static const assignableForLeaderRegistration = [
    leader,
    supervisor,
    registrar,
  ];

  static String localizedLabel(String role, AppLocalizations l10n) {
    switch (role) {
      case superAdmin:
        return l10n.roleSuperAdmin;
      case admin:
        return l10n.roleAdmin;
      case registrar:
        return l10n.roleRegistrar;
      case supervisor:
        return l10n.roleSupervisor;
      case leader:
        return l10n.roleLeader;
      default:
        return role;
    }
  }

  static String label(String role) {
    switch (role) {
      case superAdmin:
        return 'Super administrador';
      case admin:
        return 'Administrador de iglesia';
      case registrar:
        return 'Registrador';
      case supervisor:
        return 'Supervisor';
      case leader:
        return 'Líder';
      default:
        return role;
    }
  }

  static List<String> parseList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim().toLowerCase())
          .where((r) => all.contains(r))
          .toList();
    }
    if (value is String) {
      final role = value.trim().toLowerCase();
      if (role.isNotEmpty && all.contains(role)) {
        return [role];
      }
    }
    return [];
  }

  /// Administrador no puede asignarse desde el registro de líderes.
  /// El rol registrador es exclusivo: no se combina con líder ni supervisor.
  static List<String> sanitizeForLeaderRegistration(Iterable<String> roles) {
    final set = roles
        .where((r) => assignableForLeaderRegistration.contains(r))
        .toSet();
    if (set.contains(registrar)) {
      return [registrar];
    }
    if (set.isEmpty) {
      set.add(leader);
    }
    return set.toList()..sort();
  }

  static const adminAccessRoles = {superAdmin, admin};

  static bool hasAdminAccess(Iterable<String> roles) {
    return roles.any(adminAccessRoles.contains);
  }
}
