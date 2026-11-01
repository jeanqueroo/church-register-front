class CellHelper {
  const CellHelper({
    required this.memberId,
    required this.fullName,
  });

  final String memberId;
  final String fullName;

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'fullName': fullName,
    };
  }

  factory CellHelper.fromMap(Map<String, dynamic> data) {
    return CellHelper(
      memberId: data['memberId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
    );
  }

  static List<CellHelper> listFromFirestore(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((entry) => CellHelper.fromMap(Map<String, dynamic>.from(entry)))
        .where((helper) => helper.memberId.trim().isNotEmpty)
        .toList();
  }
}
