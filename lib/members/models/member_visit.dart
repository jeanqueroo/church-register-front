import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import 'spiritual_state.dart';
import 'visit_place.dart';

class MemberVisit {
  const MemberVisit({
    this.id,
    required this.memberId,
    required this.leaderId,
    required this.visitDate,
    required this.comment,
    required this.visitPlace,
    this.approximateDuration,
    required this.prayerPerformed,
    this.prayerRequests,
    required this.needsFollowUp,
    this.spiritualState,
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
  });

  final String? id;
  final String memberId;
  final String leaderId;
  final DateTime visitDate;
  final String comment;
  final VisitPlace visitPlace;
  final String? approximateDuration;
  final bool prayerPerformed;
  final String? prayerRequests;
  final bool needsFollowUp;
  final SpiritualState? spiritualState;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'leaderId': leaderId,
      'visitDate': Timestamp.fromDate(visitDate),
      'comment': comment.trim(),
      'visitPlace': visitPlace.name,
      if (approximateDuration != null && approximateDuration!.trim().isNotEmpty)
        'approximateDuration': approximateDuration!.trim(),
      'prayerPerformed': prayerPerformed,
      if (prayerRequests != null && prayerRequests!.trim().isNotEmpty)
        'prayerRequests': prayerRequests!.trim(),
      'needsFollowUp': needsFollowUp,
      if (spiritualState != null) 'spiritualState': spiritualState!.name,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory MemberVisit.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MemberVisit(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      leaderId: data['leaderId'] as String? ?? '',
      visitDate: _readDate(data['visitDate']) ?? DateTime.now(),
      comment: data['comment'] as String? ?? '',
      visitPlace:
          VisitPlace.fromString(data['visitPlace'] as String?) ?? VisitPlace.casa,
      approximateDuration: data['approximateDuration'] as String?,
      prayerPerformed: data['prayerPerformed'] as bool? ?? false,
      prayerRequests: data['prayerRequests'] as String?,
      needsFollowUp: data['needsFollowUp'] as bool? ?? false,
      spiritualState:
          SpiritualState.fromString(data['spiritualState'] as String?),
      registeredAt: _readDate(data['registeredAt']) ?? DateTime.now(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  List<String> summaryLinesFor(AppLocalizations l10n) {
    String yesNo(bool value) => value ? l10n.commonYes : l10n.commonNo;
    return [
      visitPlace.localizedLabel(l10n),
      if (approximateDuration != null && approximateDuration!.trim().isNotEmpty)
        l10n.visitDuration(approximateDuration!.trim()),
      l10n.visitPrayer(yesNo(prayerPerformed)),
      if (prayerRequests != null && prayerRequests!.trim().isNotEmpty)
        l10n.visitRequests(prayerRequests!.trim()),
      l10n.visitFollowUp(yesNo(needsFollowUp)),
      if (spiritualState != null)
        l10n.visitSpiritualState(spiritualState!.localizedLabel(l10n)),
      comment,
    ];
  }

  List<String> get summaryLines {
    final lines = <String>[
      visitPlace.label,
      if (approximateDuration != null && approximateDuration!.trim().isNotEmpty)
        'Duración: ${approximateDuration!.trim()}',
      'Oración: ${prayerPerformed ? 'Sí' : 'No'}',
      if (prayerRequests != null && prayerRequests!.trim().isNotEmpty)
        'Peticiones: ${prayerRequests!.trim()}',
      'Seguimiento: ${needsFollowUp ? 'Sí' : 'No'}',
      if (spiritualState != null) 'Estado: ${spiritualState!.label}',
      comment,
    ];
    return lines;
  }
}
