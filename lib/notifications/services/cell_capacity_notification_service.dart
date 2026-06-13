import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cells/models/church_cell.dart';

/// Avisa a administradores de la iglesia cuando una célula supera el cupo.
class CellCapacityNotificationService {
  CellCapacityNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _notifications = (firestore ?? FirebaseFirestore.instance)
            .collection('notifications'),
        _churches = (firestore ?? FirebaseFirestore.instance)
            .collection('churches');

  static const int capacityThreshold = 12;

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _notifications;
  final CollectionReference<Map<String, dynamic>> _churches;

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
      });
    }
    await batch.commit();
    return true;
  }

  Future<List<String>> _fetchAdminUserIds(String churchId) async {
    final doc = await _churches.doc(churchId).get();
    if (!doc.exists) return [];

    final raw = doc.data()?['adminUserIds'];
    if (raw is! List) return [];

    return raw
        .whereType<String>()
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }
}
