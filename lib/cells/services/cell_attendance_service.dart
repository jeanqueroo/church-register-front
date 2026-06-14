import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
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

  Future<String> addSession(CellAttendanceSession session) async {
    final doc = await _sessions(session.cellId).add(session.toMap());
    return doc.id;
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
