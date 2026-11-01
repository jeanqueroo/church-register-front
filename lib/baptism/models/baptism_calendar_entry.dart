import 'package:cloud_firestore/cloud_firestore.dart';

import 'baptism_assigned_member.dart';

/// Fecha programada de bautismo (colección `baptismCalendar`).
class BaptismCalendarEntry {
  const BaptismCalendarEntry({
    this.id,
    required this.baptismDate,
    this.time,
    this.location,
    this.notes,
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
    this.assignedMembers = const [],
  });

  final String? id;
  final DateTime baptismDate;
  final String? time;
  final String? location;
  final String? notes;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;
  final List<BaptismAssignedMember> assignedMembers;

  DateTime get dateOnly =>
      DateTime(baptismDate.year, baptismDate.month, baptismDate.day);

  Map<String, dynamic> toMap() {
    return {
      'baptismDate': Timestamp.fromDate(dateOnly),
      if (time != null && time!.trim().isNotEmpty) 'time': time!.trim(),
      if (location != null && location!.trim().isNotEmpty)
        'location': location!.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
      'assignedMembers': BaptismAssignedMember.toFirestoreList(assignedMembers),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BaptismCalendarEntry copyWith({
    String? id,
    DateTime? baptismDate,
    String? time,
    String? location,
    String? notes,
    DateTime? registeredAt,
    String? registeredBy,
    String? churchId,
    List<BaptismAssignedMember>? assignedMembers,
  }) {
    return BaptismCalendarEntry(
      id: id ?? this.id,
      baptismDate: baptismDate ?? this.baptismDate,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      registeredAt: registeredAt ?? this.registeredAt,
      registeredBy: registeredBy ?? this.registeredBy,
      churchId: churchId ?? this.churchId,
      assignedMembers: assignedMembers ?? this.assignedMembers,
    );
  }

  factory BaptismCalendarEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final baptismDate = (data['baptismDate'] as Timestamp).toDate();
    return BaptismCalendarEntry(
      id: doc.id,
      baptismDate: baptismDate,
      time: data['time'] as String?,
      location: data['location'] as String?,
      notes: data['notes'] as String?,
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
      assignedMembers: BaptismAssignedMember.fromFirestoreList(
        data['assignedMembers'],
      ),
    );
  }
}
