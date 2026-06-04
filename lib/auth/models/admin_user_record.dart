import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/person_name.dart';

/// Administrador de iglesia (documento en `users` + ficha en `leaders`).
class AdminUserRecord {
  const AdminUserRecord({
    required this.uid,
    required this.email,
    this.leaderId,
    this.firstName = '',
    this.lastName = '',
    this.churchId,
    this.isBlocked = false,
    this.legacyFullName = '',
  });

  final String uid;
  final String email;
  final String? leaderId;
  final String firstName;
  final String lastName;
  final String? churchId;
  final bool isBlocked;

  /// Nombre legado en `users` (solo lectura de datos antiguos).
  final String legacyFullName;

  String get fullName {
    final fromLeader = PersonName.join(firstName, lastName);
    if (fromLeader.isNotEmpty) return fromLeader;
    return legacyFullName.trim();
  }

  String get displayName {
    final name = fullName;
    if (name.isNotEmpty) return name;
    return email.trim().isNotEmpty ? email : '(Sin nombre)';
  }

  factory AdminUserRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AdminUserRecord(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      leaderId: data['leaderId'] as String?,
      churchId: data['churchId'] as String?,
      isBlocked: data['isBlocked'] as bool? ?? false,
      legacyFullName: data['fullName'] as String? ?? '',
    );
  }

  AdminUserRecord withLeaderNames({
    required String firstName,
    required String lastName,
  }) {
    return AdminUserRecord(
      uid: uid,
      email: email,
      leaderId: leaderId,
      firstName: firstName,
      lastName: lastName,
      churchId: churchId,
      isBlocked: isBlocked,
      legacyFullName: legacyFullName,
    );
  }
}
