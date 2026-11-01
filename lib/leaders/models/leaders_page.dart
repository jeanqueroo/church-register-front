import 'package:cloud_firestore/cloud_firestore.dart';

import 'church_leader.dart';

class LeadersPage {
  const LeadersPage({
    required this.leaders,
    required this.hasMore,
    this.lastDocument,
  });

  final List<ChurchLeader> leaders;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}
