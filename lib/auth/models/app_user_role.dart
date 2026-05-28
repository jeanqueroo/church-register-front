/// Identificadores de rol en Firestore (`users.roles`).
class AppUserRole {
  AppUserRole._();

  static const String admin = 'admin';
  static const String registrar = 'registrador';
  static const String leader = 'leader';
  static const String supervisor = 'supervisor';

  static const all = [admin, registrar, leader, supervisor];

  /// Roles que se pueden asignar al registrar o editar un líder (nunca admin).
  static const assignableForLeaderRegistration = [
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

  /// Filtra roles válidos para cuentas de líder; excluye admin.
  static List<String> sanitizeForLeaderRegistration(Iterable<String> roles) {
    return roles
        .where((r) => assignableForLeaderRegistration.contains(r))
        .toSet()
        .toList()
      ..sort();
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
