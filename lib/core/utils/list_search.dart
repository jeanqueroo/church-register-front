import '../../auth/models/app_user_role.dart';
import '../../leaders/models/church_leader.dart';
import '../../members/models/church_member.dart';
import '../../members/models/leader_member_group.dart';

String normalizeSearchQuery(String query) => query.trim().toLowerCase();

bool matchesSearchQuery(String query, Iterable<String?> fields) {
  final q = normalizeSearchQuery(query);
  if (q.isEmpty) return true;
  for (final field in fields) {
    final text = field?.trim().toLowerCase();
    if (text != null && text.isNotEmpty && text.contains(q)) {
      return true;
    }
  }
  return false;
}

bool memberMatchesSearch(ChurchMember member, String query) {
  return matchesSearchQuery(query, [
    member.fullName,
    member.firstName,
    member.lastName,
    member.phone,
    member.locality,
    member.neighborhood,
    member.street,
    member.stateProvince,
    member.assignedLeaderName,
    member.assignedLeaderCellCode,
    member.occupation,
    member.cellZone,
    member.cellDay,
    member.observations,
    member.formattedAddress,
  ]);
}

bool leaderMatchesSearch(
  ChurchLeader leader,
  String query, {
  List<String> appRoles = const [],
}) {
  return matchesSearchQuery(query, [
    leader.fullName,
    leader.firstName,
    leader.lastName,
    leader.mobilePhone,
    leader.email,
    leader.churchOfficeLabel,
    leader.cellCode,
    leader.locality,
    leader.neighborhood,
    leader.street,
    leader.formattedAddress,
    for (final role in appRoles) AppUserRole.label(role),
  ]);
}

List<LeaderMemberGroup> filterLeaderMemberGroups(
  List<LeaderMemberGroup> groups,
  String query,
) {
  final q = normalizeSearchQuery(query);
  if (q.isEmpty) return groups;

  final filtered = <LeaderMemberGroup>[];
  for (final group in groups) {
    final leaderMatches = matchesSearchQuery(q, [
      group.leaderName,
      group.cellCode,
    ]);
    if (leaderMatches) {
      filtered.add(group);
      continue;
    }

    final matchingMembers =
        group.members.where((m) => memberMatchesSearch(m, q)).toList();
    if (matchingMembers.isEmpty) continue;

    filtered.add(
      LeaderMemberGroup(
        leaderKey: group.leaderKey,
        leaderName: group.leaderName,
        cellCode: group.cellCode,
        members: matchingMembers,
        isUnassigned: group.isUnassigned,
      ),
    );
  }
  return filtered;
}
