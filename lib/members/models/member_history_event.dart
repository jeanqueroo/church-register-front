import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';

enum MemberHistoryEventType {
  registered,
  pastoralAssigned,
  cellAssigned,
  cellUnassigned,
  baptizedConfirmed;

  String get storageKey => name;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case MemberHistoryEventType.registered:
        return l10n.memberHistoryEventRegistered;
      case MemberHistoryEventType.pastoralAssigned:
        return l10n.memberHistoryEventPastoralAssigned;
      case MemberHistoryEventType.cellAssigned:
        return l10n.memberHistoryEventCellAssigned;
      case MemberHistoryEventType.cellUnassigned:
        return l10n.memberHistoryEventCellUnassigned;
      case MemberHistoryEventType.baptizedConfirmed:
        return l10n.memberHistoryEventBaptizedConfirmed;
    }
  }
}

class MemberHistoryEvent {
  const MemberHistoryEvent({
    required this.type,
    required this.occurredAt,
    this.performedBy,
    this.details = const {},
  });

  final MemberHistoryEventType type;
  final DateTime occurredAt;
  final String? performedBy;
  final Map<String, dynamic> details;

  Map<String, dynamic> toMap() {
    return {
      'type': type.storageKey,
      'occurredAt': Timestamp.fromDate(occurredAt),
      if (performedBy != null && performedBy!.trim().isNotEmpty)
        'performedBy': performedBy!.trim(),
      if (details.isNotEmpty) 'details': details,
    };
  }

  factory MemberHistoryEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MemberHistoryEvent(
      type: MemberHistoryEventType.values.firstWhere(
        (value) => value.storageKey == data['type'],
        orElse: () => MemberHistoryEventType.registered,
      ),
      occurredAt: (data['occurredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      performedBy: data['performedBy'] as String?,
      details: Map<String, dynamic>.from(
        (data['details'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
