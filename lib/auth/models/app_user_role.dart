/// Identificadores de rol en Firestore (`users.roles`).
class AppUserRole {
  AppUserRole._();

  static const String admin = 'admin';
  static const String registrar = 'registrador';
  static const String leader = 'leader';

  static const all = [admin, registrar, leader];

  static String label(String role) {
    switch (role) {
      case admin:
        return 'Administrador';
      case registrar:
        return 'Registrador';
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
}
