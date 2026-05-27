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
    required String fullName,
  }) {
    return _users.doc(uid).set({
      'email': email.trim().toLowerCase(),
      'roles': [AppUserRole.leader],
      'leaderId': leaderId,
      'fullName': fullName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
}
