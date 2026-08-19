import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';

/// Aviso para un líder cuando se le asigna un integrante.
class LeaderNotification {
  const LeaderNotification({
    this.id,
    this.recipientUserId,
    required this.leaderId,
    required this.memberId,
    required this.memberName,
    required this.createdAt,
    this.read = false,
  });

  final String? id;
  final String? recipientUserId;
  final String leaderId;
  final String memberId;
  final String memberName;
  final DateTime createdAt;
  final bool read;

  String localizedTitle(AppLocalizations l10n) => l10n.notificationNewMemberTitle;

  String localizedBody(AppLocalizations l10n) =>
      l10n.notificationNewMemberBody(memberName);

  Map<String, dynamic> toMap() {
    return {
      if (recipientUserId != null) 'recipientUserId': recipientUserId,
      'leaderId': leaderId,
      'memberId': memberId,
      'memberName': memberName,
      'type': 'member_assigned',
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory LeaderNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return LeaderNotification(
      id: doc.id,
      recipientUserId: data['recipientUserId'] as String?,
      leaderId: data['leaderId'] as String? ?? '',
      memberId: data['memberId'] as String? ?? '',
      memberName: data['memberName'] as String? ?? 'Integrante',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
    );
  }
}
