import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cells/models/church_cell.dart';
import '../../auth/models/app_user_role.dart';

/// Avisa a administradores de la iglesia cuando una célula supera el cupo.
class CellCapacityNotificationService {
  CellCapacityNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _notifications = (firestore ?? FirebaseFirestore.instance)
            .collection('notifications'),
        _churches = (firestore ?? FirebaseFirestore.instance)
            .collection('churches'),
        _users = (firestore ?? FirebaseFirestore.instance)
            .collection('users');

  static const int capacityThreshold = 12;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _notifications;
  final CollectionReference<Map<String, dynamic>> _churches;
  final CollectionReference<Map<String, dynamic>> _users;

  /// Notifica a los administradores si [memberCount] supera [capacityThreshold].
  Future<bool> notifyAdminsIfExceeded({
    required ChurchCell cell,
    required int memberCount,
    required String memberId,
    required String memberName,
  }) async {
    if (memberCount <= capacityThreshold) return false;

    final churchId = cell.churchId?.trim();
    final cellId = cell.id?.trim();
    if (churchId == null ||
        churchId.isEmpty ||
        cellId == null ||
        cellId.isEmpty) {
      return false;
    }

    final adminIds = await _fetchAdminUserIds(churchId);
    if (adminIds.isEmpty) return false;

    final batch = _firestore.batch();
    for (final adminUid in adminIds) {
      final ref = _notifications.doc();
      batch.set(ref, {
        'type': 'cell_capacity_exceeded',
        'recipientUserId': adminUid,
        'churchId': churchId,
        'cellId': cellId,
        'cellCode': cell.code.trim(),
        'cellName': cell.name?.trim(),
        'memberCount': memberCount,
        'memberId': memberId,
        'memberName': memberName,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return true;
  }

  Future<List<String>> _fetchAdminUserIds(String churchId) async {
    final ids = <String>{};

    final doc = await _churches.doc(churchId).get();
    if (doc.exists) {
      final raw = doc.data()?['adminUserIds'];
      if (raw is List) {
        ids.addAll(
          raw
              .whereType<String>()
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty),
        );
      }
    }

    try {
      final snapshot = await _users
          .where('churchId', isEqualTo: churchId)
          .where('roles', arrayContains: AppUserRole.admin)
          .get();
      ids.addAll(snapshot.docs.map((userDoc) => userDoc.id));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }

    return ids.toList();
  }
}
