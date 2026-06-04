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
      return value.map((e) => e.toString()).where((r) => all.contains(r)).toList();
    }
    if (value is String && value.isNotEmpty && all.contains(value)) {
      return [value];
    }
    return [];
  }

  /// Administrador no puede asignarse desde el registro de líderes.
  static List<String> sanitizeForLeaderRegistration(Iterable<String> roles) {
    final set = roles
        .where((r) => assignableForLeaderRegistration.contains(r))
        .toSet();
    if (set.isEmpty) {
      set.add(leader);
    }
    return set.toList()..sort();
  }
}
