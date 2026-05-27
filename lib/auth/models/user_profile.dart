import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_permissions.dart';
import 'app_user_role.dart';

class UserProfile {
  const UserProfile({
    required this.roles,
    this.leaderId,
    this.fullName,
    this.email,
  });

  final List<String> roles;
  final String? leaderId;
  final String? fullName;
  final String? email;

  AppPermissions get permissions => AppPermissions.fromRoles(roles);

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    var roles = AppUserRole.parseList(data['roles']);
    if (roles.isEmpty) {
      roles = AppUserRole.parseList(data['role']);
    }
    return UserProfile(
      roles: roles,
      leaderId: data['leaderId'] as String?,
      fullName: data['fullName'] as String?,
      email: data['email'] as String?,
    );
  }
}

class UserSession {
  const UserSession({
    required this.uid,
    required this.email,
    required this.profile,
  });

  final String uid;
  final String email;
  final UserProfile profile;

  AppPermissions get permissions => profile.permissions;
}
