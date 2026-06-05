class FollowUpPerson {
  const FollowUpPerson({
    required this.memberId,
    required this.memberName,
    required this.visitDate,
    required this.leaderId,
    this.leaderName,
  });

  final String memberId;
  final String memberName;
  final DateTime visitDate;
  final String leaderId;
  final String? leaderName;
}
