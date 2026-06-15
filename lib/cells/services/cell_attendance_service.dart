import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../../members/services/member_service.dart';
import '../models/cell_attendance_session.dart';

class CellAttendanceService {
  CellAttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String cellId) {
    return _firestore.collection('cells').doc(cellId).collection('sessions');
  }

  Stream<List<CellAttendanceSession>> watchSessions(String cellId) {
    return _sessions(cellId)
        .orderBy('sessionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CellAttendanceSession.fromFirestore)
              .toList(),
        );
  }

  Future<List<CellAttendanceSession>> fetchSessions(String cellId) async {
    final snapshot = await _sessions(cellId)
        .orderBy('sessionDate', descending: true)
        .get();
    return snapshot.docs.map(CellAttendanceSession.fromFirestore).toList();
  }

  Future<String> addSession(
    CellAttendanceSession session, {
    MemberService? memberService,
  }) async {
    final doc = await _sessions(session.cellId).add(session.toMap());
    await (memberService ?? MemberService())
        .graduateNewBelieversFromCellAttendance(cellId: session.cellId);
    return doc.id;
  }

  Future<void> updateSession(
    CellAttendanceSession session, {
    MemberService? memberService,
  }) async {
    final sessionId = session.id?.trim();
    if (sessionId == null || sessionId.isEmpty) {
      throw ArgumentError('session.id is required to update');
    }
    await _sessions(session.cellId).doc(sessionId).set(session.toMap());
    await (memberService ?? MemberService())
        .graduateNewBelieversFromCellAttendance(cellId: session.cellId);
  }

  Future<void> deleteSession({
    required String cellId,
    required String sessionId,
    MemberService? memberService,
  }) async {
    if (cellId.isEmpty || sessionId.isEmpty) {
      throw ArgumentError('cellId and sessionId are required');
    }
    await _sessions(cellId).doc(sessionId).delete();
    await (memberService ?? MemberService())
        .graduateNewBelieversFromCellAttendance(cellId: cellId);
  }

  static String messageFromFirestoreException(
    FirebaseException e,
    AppLocalizations l10n,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return l10n.firestorePermissionDenied;
      case 'unavailable':
        return l10n.firestoreUnavailable;
      default:
        return l10n.firestoreGenericError;
    }
  }
}
