import '../../members/models/church_member.dart';
import '../models/church_leader.dart';

/// Misma regla que [groupMembersByLeader] para un [leader] concreto.
bool isMemberAssignedToLeader(ChurchMember member, ChurchLeader leader) {
  final memberLeaderId = member.assignedLeaderId?.trim();
  final memberLeaderName = member.assignedLeaderName?.trim();

  if ((memberLeaderId == null || memberLeaderId.isEmpty) &&
      (memberLeaderName == null || memberLeaderName.isEmpty)) {
    return false;
  }

  final leaderId = leader.id?.trim();
  if (leaderId != null &&
      leaderId.isNotEmpty &&
      memberLeaderId == leaderId) {
    return true;
  }

  if ((memberLeaderId == null || memberLeaderId.isEmpty) &&
      memberLeaderName != null &&
      memberLeaderName.isNotEmpty) {
    return memberLeaderName.trim().toLowerCase() ==
        leader.fullName.trim().toLowerCase();
  }

  return false;
}

/// Creyentes asignados pastoralmente a [leader] (registro de creyente, bautismo, etc.).
List<ChurchMember> membersAssignedToLeader(
  ChurchLeader leader,
  List<ChurchMember> members,
) {
  final assigned = members
      .where((member) => isMemberAssignedToLeader(member, leader))
      .where((member) => member.isNewBeliever)
      .where((member) => member.isPastoralLeaderAssignment)
      .toList();

  assigned.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
  return assigned;
}
