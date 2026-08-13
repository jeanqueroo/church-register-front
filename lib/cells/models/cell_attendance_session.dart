import 'package:cloud_firestore/cloud_firestore.dart';

import 'cell_attendance_record.dart';

class CellAttendanceSession {
  const CellAttendanceSession({
    this.id,
    required this.cellId,
    required this.cellCode,
    required this.sessionDate,
    required this.sessionTime,
    required this.place,
    this.registeredCellDay,
    required this.sessionWeekday,
    required this.dayDiffersFromRegistered,
    required this.noteDayChangeForSession,
    this.dayChangeReason,
    required this.registeredPlace,
    required this.locationDiffersFromRegistered,
    required this.noteLocationChangeForSession,
    this.locationChangeReason,
    this.offeringCollected,
    this.observations,
    required this.records,
    required this.presentCount,
    required this.totalCount,
    required this.leaderId,
    this.leaderName,
    required this.registeredAt,
    required this.registeredBy,
    this.churchId,
  });

  final String? id;
  final String cellId;
  final String cellCode;
  final DateTime sessionDate;
  final String sessionTime;
  final String place;
  final String? registeredCellDay;
  final String sessionWeekday;
  final bool dayDiffersFromRegistered;
  final bool noteDayChangeForSession;
  final String? dayChangeReason;
  final String registeredPlace;
  final bool locationDiffersFromRegistered;
  final bool noteLocationChangeForSession;
  final String? locationChangeReason;
  final String? offeringCollected;
  final String? observations;
  final List<CellAttendanceRecord> records;
  final int presentCount;
  final int totalCount;
  final String leaderId;
  final String? leaderName;
  final DateTime registeredAt;
  final String registeredBy;
  final String? churchId;

  Map<String, dynamic> toMap() {
    return {
      'cellId': cellId,
      'cellCode': cellCode,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'sessionTime': sessionTime,
      'place': place,
      if (registeredCellDay != null && registeredCellDay!.trim().isNotEmpty)
        'registeredCellDay': registeredCellDay,
      'sessionWeekday': sessionWeekday,
      'dayDiffersFromRegistered': dayDiffersFromRegistered,
      'noteDayChangeForSession': noteDayChangeForSession,
      if (dayChangeReason != null && dayChangeReason!.trim().isNotEmpty)
        'dayChangeReason': dayChangeReason!.trim(),
      'registeredPlace': registeredPlace,
      'locationDiffersFromRegistered': locationDiffersFromRegistered,
      'noteLocationChangeForSession': noteLocationChangeForSession,
      if (locationChangeReason != null &&
          locationChangeReason!.trim().isNotEmpty)
        'locationChangeReason': locationChangeReason!.trim(),
      if (offeringCollected != null && offeringCollected!.trim().isNotEmpty)
        'offeringCollected': offeringCollected!.trim(),
      if (observations != null && observations!.trim().isNotEmpty)
        'observations': observations!.trim(),
      'records': records.map((record) => record.toMap()).toList(),
      'presentCount': presentCount,
      'totalCount': totalCount,
      'leaderId': leaderId,
      if (leaderName != null && leaderName!.trim().isNotEmpty)
        'leaderName': leaderName!.trim(),
      'registeredAt': Timestamp.fromDate(registeredAt),
      'registeredBy': registeredBy,
      if (churchId != null && churchId!.isNotEmpty) 'churchId': churchId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CellAttendanceSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final records = CellAttendanceRecord.listFromFirestore(data['records']);
    return CellAttendanceSession(
      id: doc.id,
      cellId: data['cellId'] as String? ?? '',
      cellCode: data['cellCode'] as String? ?? '',
      sessionDate: (data['sessionDate'] as Timestamp).toDate(),
      sessionTime: data['sessionTime'] as String? ?? '',
      place: data['place'] as String? ?? '',
      registeredCellDay: data['registeredCellDay'] as String?,
      sessionWeekday: data['sessionWeekday'] as String? ?? '',
      dayDiffersFromRegistered:
          data['dayDiffersFromRegistered'] as bool? ?? false,
      noteDayChangeForSession:
          data['noteDayChangeForSession'] as bool? ?? false,
      dayChangeReason: data['dayChangeReason'] as String?,
      registeredPlace: data['registeredPlace'] as String? ?? '',
      locationDiffersFromRegistered:
          data['locationDiffersFromRegistered'] as bool? ?? false,
      noteLocationChangeForSession:
          data['noteLocationChangeForSession'] as bool? ?? false,
      locationChangeReason: data['locationChangeReason'] as String?,
      offeringCollected: data['offeringCollected'] as String?,
      observations: data['observations'] as String?,
      records: records,
      presentCount: data['presentCount'] as int? ?? records.where((r) => r.present).length,
      totalCount: data['totalCount'] as int? ?? records.length,
      leaderId: data['leaderId'] as String? ?? '',
      leaderName: data['leaderName'] as String?,
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      registeredBy: data['registeredBy'] as String? ?? '',
      churchId: data['churchId'] as String?,
    );
  }
}
