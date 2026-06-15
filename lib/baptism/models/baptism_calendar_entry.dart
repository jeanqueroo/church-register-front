import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String? id;
  final DateTime baptismDate;
  final String? time;
  final String? location;
  final String? notes;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;

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
    };
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
    );
  }
}
