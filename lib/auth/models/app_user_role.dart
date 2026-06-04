/// Identificadores de rol en Firestore (`users.roles`).
class AppUserRole {
  AppUserRole._();

  static const String admin = 'admin';
  static const String registrar = 'registrador';
  static const String leader = 'leader';
  static const String supervisor = 'supervisor';

  static const all = [admin, registrar, leader, supervisor];

  /// Roles asignables al registrar o editar un líder (incluye administrador).
  static const assignableForLeaderRegistration = [
    admin,
    leader,
    registrar,
    supervisor,
  ];

  static String label(String role) {
    switch (role) {
      case admin:
        return 'Administrador';
      case registrar:
        return 'Registrador';
      case leader:
        return 'Líder';
      case supervisor:
        return 'Supervisor';
      default:
        return role;
    }
  }

  /// Administrador no puede combinarse con ningún otro rol.
  static bool hasAdminWithOtherRolesConflict(Iterable<String> roles) {
    final set = roles.toSet();
    return set.contains(admin) && set.length > 1;
  }

  /// Filtra roles válidos para cuentas de líder y resuelve conflictos.
  static List<String> sanitizeForLeaderRegistration(Iterable<String> roles) {
    final set = roles
        .where((r) => assignableForLeaderRegistration.contains(r))
        .toSet();
    if (set.contains(admin)) {
      return [admin];
    }
    return set.toList()..sort();
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
}
