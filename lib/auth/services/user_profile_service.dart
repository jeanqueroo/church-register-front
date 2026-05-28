import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_role.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
      : _users = (firestore ?? FirebaseFirestore.instance).collection('users');

  final CollectionReference<Map<String, dynamic>> _users;

  Future<void> setLeaderProfile({
    required String uid,
    required String email,
    required String leaderId,
    List<String>? roles,
  }) {
    final effectiveRoles =
        AppUserRole.sanitizeForLeaderRegistration(roles ?? []);
    return _users.doc(uid).set({
      'email': email.trim().toLowerCase(),
      'roles': effectiveRoles,
      'leaderId': leaderId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserRoles({
    required String uid,
    required List<String> roles,
  }) {
    final effectiveRoles = AppUserRole.sanitizeForLeaderRegistration(roles);
    return _users.doc(uid).set(
      {
        'roles': effectiveRoles,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> fetchProfileDoc(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc;
  }

  Future<void> updatePersonalData({
    required String uid,
    required String fullName,
    required String email,
  }) {
    return _users.doc(uid).set(
      {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) {
    return _users.doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
