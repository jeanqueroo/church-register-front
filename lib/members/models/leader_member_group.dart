import 'church_member.dart';

/// Integrantes agrupados bajo un mismo líder asignado.
class LeaderMemberGroup {
  const LeaderMemberGroup({
    required this.leaderKey,
    required this.leaderName,
    this.cellCode,
    required this.members,
    this.isUnassigned = false,
  });

  final String leaderKey;
  final String leaderName;
  final String? cellCode;
  final List<ChurchMember> members;
  final bool isUnassigned;

  int get count => members.length;
}

const _unassignedKey = '__unassigned__';

List<LeaderMemberGroup> groupMembersByLeader(List<ChurchMember> members) {
  final buckets = <String, List<ChurchMember>>{};
  final names = <String, String>{};
  final cells = <String, String?>{};
  final unassigned = <ChurchMember>[];

  for (final member in members) {
    final leaderId = member.assignedLeaderId?.trim();
    final leaderName = member.assignedLeaderName?.trim();

    if ((leaderId == null || leaderId.isEmpty) &&
        (leaderName == null || leaderName.isEmpty)) {
      unassigned.add(member);
      continue;
    }

    final key = (leaderId != null && leaderId.isNotEmpty)
        ? leaderId
        : leaderName!.toLowerCase();

    buckets.putIfAbsent(key, () => []).add(member);
    names[key] = leaderName ?? 'Líder';
    cells[key] = member.assignedLeaderCellCode;
  }

  final groups = buckets.entries.map((entry) {
    final list = List<ChurchMember>.from(entry.value)
      ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

    return LeaderMemberGroup(
      leaderKey: entry.key,
      leaderName: names[entry.key]!,
      cellCode: cells[entry.key],
      members: list,
    );
  }).toList()
    ..sort((a, b) => a.leaderName.compareTo(b.leaderName));

  if (unassigned.isNotEmpty) {
    unassigned.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
    groups.add(
      LeaderMemberGroup(
        leaderKey: _unassignedKey,
        leaderName: 'Sin líder asignado',
        members: unassigned,
        isUnassigned: true,
      ),
    );
  }

  return groups;
}
