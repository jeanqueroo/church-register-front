import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_user_record.dart';
import '../models/app_user_role.dart';
import '../models/user_profile.dart';
import '../../core/firebase/app_check_bootstrap.dart';
import '../../l10n/app_localizations.dart';

class UserProfileService {
  UserProfileService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _users = (firestore ?? FirebaseFirestore.instance).collection('users'),
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _users;
  final FirebaseStorage _storage;

  Future<void> setLeaderProfile({
    required String uid,
    required String email,
    required String leaderId,
    required List<String> roles,
    String? churchId,
  }) {
    final data = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'roles': AppUserRole.sanitizeForLeaderRegistration(roles),
      'leaderId': leaderId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (churchId != null && churchId.isNotEmpty) {
      data['churchId'] = churchId;
    }
    return _users.doc(uid).set(data);
  }

  Future<void> updateUserRoles({
    required String uid,
    required List<String> roles,
  }) {
    return _users.doc(uid).set(
      {
        'roles': AppUserRole.sanitizeForLeaderRegistration(roles),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setAdminProfile({
    required String uid,
    required String email,
    required String churchId,
    required String leaderId,
  }) async {
    await _users.doc(uid).set({
      'email': email.trim().toLowerCase(),
      'roles': [AppUserRole.admin],
      'churchId': churchId,
      'leaderId': leaderId,
      'isBlocked': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (churchId.isNotEmpty) {
      await _firestore.collection('churches').doc(churchId).set(
        {
          'adminUserIds': FieldValue.arrayUnion([uid]),
        },
        SetOptions(merge: true),
      );
    }
  }

  Stream<List<AdminUserRecord>> watchChurchAdmins() {
    return _users
        .where('roles', arrayContains: AppUserRole.admin)
        .snapshots()
        .map((snapshot) {
      final admins = snapshot.docs
          .map(AdminUserRecord.fromFirestore)
          .toList();
      admins.sort((a, b) => a.displayName.compareTo(b.displayName));
      return admins;
    });
  }

  /// Garantiza que el admin figure en `churches/{id}.adminUserIds` (avisos de célula).
  Future<void> ensureAdminListedOnChurch({
    required String uid,
    required String churchId,
  }) async {
    if (uid.isEmpty || churchId.isEmpty) return;
    await _firestore.collection('churches').doc(churchId).set(
      {
        'adminUserIds': FieldValue.arrayUnion([uid]),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateAdminUser({
    required String uid,
    required String churchId,
    required String leaderId,
  }) async {
    await _users.doc(uid).set(
      {
        'churchId': churchId,
        'leaderId': leaderId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (churchId.isNotEmpty) {
      await _firestore.collection('churches').doc(churchId).set(
        {
          'adminUserIds': FieldValue.arrayUnion([uid]),
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> setAdminBlocked({
    required String uid,
    required bool blocked,
    required String updatedBy,
  }) {
    return setUserBlocked(uid: uid, blocked: blocked, updatedBy: updatedBy);
  }

  Future<void> setUserBlocked({
    required String uid,
    required bool blocked,
    required String updatedBy,
  }) {
    return _users.doc(uid).update({
      'isBlocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });
  }

  static String messageFromException(Object e, AppLocalizations l10n) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return l10n.userProfileAdminPermissionDenied;
        case 'unavailable':
          return l10n.serviceUnavailable;
        default:
          return l10n.userProfileError(e.message ?? e.code);
      }
    }
    return l10n.serviceGenericError;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> fetchProfileDoc(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc;
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> updateUserEmail({
    required String uid,
    required String email,
  }) {
    return _users.doc(uid).set(
      {
        'email': email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> uploadProfilePhoto(
    Uint8List bytes, {
    required String uid,
    String? contentType,
  }) async {
    await ensureAppCheckTokenForUpload();

    final ref = _storage.ref().child('user_profiles/$uid/photo.jpg');
    if (kDebugMode) {
      debugPrint('Storage upload → gs://${_storage.bucket}/user_profiles/$uid/photo.jpg');
    }
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType ?? 'image/jpeg',
        cacheControl: 'public,max-age=86400',
      ),
    );
    return ref.getDownloadURL();
  }

  Future<void> updatePhotoUrl({
    required String uid,
    required String? photoUrl,
  }) {
    final trimmed = photoUrl?.trim() ?? '';
    return _users.doc(uid).set(
      {
        if (trimmed.isNotEmpty)
          'photoUrl': trimmed
        else
          'photoUrl': FieldValue.delete(),
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
