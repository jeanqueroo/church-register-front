import 'package:cloud_firestore/cloud_firestore.dart';

import 'church_member.dart';

class MembersPage {
  const MembersPage({
    required this.members,
    required this.hasMore,
    this.lastDocument,
  });

  final List<ChurchMember> members;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}
