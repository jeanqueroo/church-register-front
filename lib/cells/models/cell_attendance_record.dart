class CellAttendanceRecord {
  const CellAttendanceRecord({
    required this.memberId,
    required this.fullName,
    required this.present,
  });

  final String memberId;
  final String fullName;
  final bool present;

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'fullName': fullName,
      'present': present,
    };
  }

  factory CellAttendanceRecord.fromMap(Map<String, dynamic> data) {
    return CellAttendanceRecord(
      memberId: data['memberId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      present: data['present'] as bool? ?? false,
    );
  }

  static List<CellAttendanceRecord> listFromFirestore(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => CellAttendanceRecord.fromMap(Map<String, dynamic>.from(entry)))
        .where((record) => record.memberId.trim().isNotEmpty)
        .toList();
  }
}
