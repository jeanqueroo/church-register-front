import 'package:cloud_firestore/cloud_firestore.dart';

/// Usuario con rol supervisor y los líderes que tiene asignados.
class SupervisorAccount {
  const SupervisorAccount({
    required this.uid,
    required this.email,
    this.leaderId,
    this.churchId,
    this.displayName,
    required this.supervisedLeaderIds,
  });

  final String uid;
  final String email;
  final String? leaderId;
  final String? churchId;
  final String? displayName;
  final List<String> supervisedLeaderIds;

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return '$name ($email)';
    }
    return email;
  }

  SupervisorAccount copyWith({
    String? displayName,
    List<String>? supervisedLeaderIds,
  }) {
    return SupervisorAccount(
      uid: uid,
      email: email,
      leaderId: leaderId,
      churchId: churchId,
      displayName: displayName ?? this.displayName,
      supervisedLeaderIds: supervisedLeaderIds ?? this.supervisedLeaderIds,
    );
  }

  static List<String> parseSupervisedLeaderIds(dynamic value) {
    if (value is! List) return [];
    return value
        .map((e) => e.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  factory SupervisorAccount.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SupervisorAccount(
      uid: doc.id,
      email: data['email'] as String? ?? doc.id,
      leaderId: data['leaderId'] as String?,
      churchId: data['churchId'] as String?,
      supervisedLeaderIds: parseSupervisedLeaderIds(data['supervisedLeaderIds']),
    );
  }

  bool matchesChurch(String? churchId) {
    if (churchId == null || churchId.isEmpty) return true;
    final mine = this.churchId?.trim();
    if (mine == null || mine.isEmpty) return false;
    return mine == churchId;
  }
}
