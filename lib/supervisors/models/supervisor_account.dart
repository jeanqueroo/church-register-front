/// Usuario con rol supervisor y los líderes que tiene asignados.
class SupervisorAccount {
  const SupervisorAccount({
    required this.uid,
    required this.email,
    this.fullName,
    required this.supervisedLeaderIds,
  });

  final String uid;
  final String email;
  final String? fullName;
  final List<String> supervisedLeaderIds;

  String get displayLabel {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) {
      return '$name ($email)';
    }
    return email;
  }
}
