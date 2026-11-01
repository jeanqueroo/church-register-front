class BaptismAssignedMember {
  const BaptismAssignedMember({
    required this.memberId,
    required this.fullName,
  });

  final String memberId;
  final String fullName;

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'fullName': fullName,
      };

  factory BaptismAssignedMember.fromMap(Map<String, dynamic> data) {
    return BaptismAssignedMember(
      memberId: data['memberId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
    );
  }

  static List<BaptismAssignedMember> fromFirestoreList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BaptismAssignedMember.fromMap)
        .where((member) => member.memberId.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> toFirestoreList(
    List<BaptismAssignedMember> members,
  ) {
    return members.map((member) => member.toMap()).toList();
  }
}
