import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';

class AdminNotification {
  const AdminNotification({
    this.id,
    required this.type,
    required this.recipientUserId,
    required this.churchId,
    required this.createdAt,
    this.read = false,
    this.cellId,
    this.cellCode,
    this.cellName,
    this.memberCount,
    this.memberId,
    this.memberName,
  });

  final String? id;
  final String type;
  final String recipientUserId;
  final String churchId;
  final DateTime createdAt;
  final bool read;
  final String? cellId;
  final String? cellCode;
  final String? cellName;
  final int? memberCount;
  final String? memberId;
  final String? memberName;

  String localizedTitle(AppLocalizations l10n) {
    switch (type) {
      case 'cell_capacity_exceeded':
        return l10n.notificationCellCapacityTitle;
      default:
        return l10n.notificationsTitle;
    }
  }

  String localizedBody(AppLocalizations l10n) {
    switch (type) {
      case 'cell_capacity_exceeded':
        final label = _cellDisplayLabel;
        final count = memberCount ?? 0;
        return l10n.notificationCellCapacityBody(label, count);
      default:
        return '';
    }
  }

  String get _cellDisplayLabel {
    final code = cellCode?.trim();
    final name = cellName?.trim();
    if (code != null && code.isNotEmpty) {
      if (name != null && name.isNotEmpty) return '$code · $name';
      return code;
    }
    return name ?? '';
  }

  factory AdminNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AdminNotification(
      id: doc.id,
      type: data['type'] as String? ?? '',
      recipientUserId: data['recipientUserId'] as String? ?? '',
      churchId: data['churchId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      cellId: data['cellId'] as String?,
      cellCode: data['cellCode'] as String?,
      cellName: data['cellName'] as String?,
      memberCount: (data['memberCount'] as num?)?.toInt(),
      memberId: data['memberId'] as String?,
      memberName: data['memberName'] as String?,
    );
  }
}
