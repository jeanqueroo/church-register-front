import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_permissions.dart';
import 'app_user_role.dart';

class UserProfile {
  const UserProfile({
    required this.roles,
    this.leaderId,
    this.churchId,
    this.fullName,
    this.email,
    this.isBlocked = false,
    this.supervisedLeaderIds = const [],
  });

  final List<String> roles;
  final String? leaderId;
  /// Iglesia asignada (administradores de una sede).
  final String? churchId;
  final String? fullName;
  final String? email;
  final bool isBlocked;
  final List<String> supervisedLeaderIds;

  AppPermissions get permissions =>
      AppPermissions.fromRoles(roles, churchId: churchId);

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    var roles = AppUserRole.parseList(data['roles']);
    if (roles.isEmpty) {
      roles = AppUserRole.parseList(data['role']);
    }
    return UserProfile(
      roles: roles,
      leaderId: data['leaderId'] as String?,
      churchId: data['churchId'] as String?,
      fullName: data['fullName'] as String?,
      email: data['email'] as String?,
      isBlocked: data['isBlocked'] as bool? ?? false,
      supervisedLeaderIds: _parseSupervisedLeaderIds(data['supervisedLeaderIds']),
    );
  }

  static List<String> _parseSupervisedLeaderIds(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((value) => value.toString().trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }
}

class UserSession {
  const UserSession({
    required this.uid,
    required this.email,
    required this.profile,
    this.displayName,
  });

  final String uid;
  final String email;
  final UserProfile profile;

  /// Nombre para mostrar: ficha en `leaders` vía [leaderId]; legado en `users.fullName`.
  final String? displayName;

  AppPermissions get permissions => profile.permissions;

  bool get isLeaderAccount =>
      profile.permissions.isLeader &&
      profile.leaderId != null &&
      profile.leaderId!.isNotEmpty;

  String get resolvedDisplayName {
    final fromLeader = displayName?.trim();
    if (fromLeader != null && fromLeader.isNotEmpty) return fromLeader;
    final fromUser = profile.fullName?.trim();
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;
    return '';
  }
}
