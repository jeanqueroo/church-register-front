import '../../members/models/church_member.dart';
import '../models/church_leader.dart';

/// Integrantes cuyo líder asignado coincide con [leader] (por id o nombre).
List<ChurchMember> membersAssignedToLeader(
  ChurchLeader leader,
  List<ChurchMember> members,
) {
  final leaderId = leader.id;
  final leaderName = leader.fullName.trim().toLowerCase();

  final assigned = members.where((member) {
    if (leaderId != null &&
        leaderId.isNotEmpty &&
        member.assignedLeaderId == leaderId) {
      return true;
    }
    final assignedName = member.assignedLeaderName?.trim().toLowerCase();
    return assignedName != null &&
        assignedName.isNotEmpty &&
        assignedName == leaderName;
  }).toList();

  assigned.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
  return assigned;
}
