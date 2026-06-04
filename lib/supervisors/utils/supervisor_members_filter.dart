import '../../leaders/models/church_leader.dart';
import '../../members/models/church_member.dart';

/// Nuevos creyentes asignados a alguno de los [leaderIds] del supervisor.
List<ChurchMember> membersAssignedToLeaders(
  Set<String> leaderIds,
  List<ChurchMember> members,
) {
  if (leaderIds.isEmpty) return [];

  final assigned = members.where((member) {
    final id = member.assignedLeaderId?.trim();
    return id != null && id.isNotEmpty && leaderIds.contains(id);
  }).toList();

  assigned.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
  return assigned;
}

/// Líderes que el supervisor tiene en su cartera.
List<ChurchLeader> leadersForSupervisor(
  Set<String> leaderIds,
  List<ChurchLeader> leaders,
) {
  if (leaderIds.isEmpty) return [];
  return leaders
      .where((l) => l.id != null && leaderIds.contains(l.id))
      .toList()
    ..sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
}
