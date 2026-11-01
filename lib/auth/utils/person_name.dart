/// Utilidades para nombre en ficha `leaders` (firstName / lastName).
class PersonName {
  PersonName._();

  static ({String firstName, String lastName}) split(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return (firstName: '', lastName: '');
    if (parts.length == 1) return (firstName: parts.first, lastName: '');
    return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
  }

  static String join(String firstName, String lastName) {
    return [firstName, lastName]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();
  }
}
