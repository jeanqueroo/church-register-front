import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../models/baptism_calendar_entry.dart';

class BaptismCalendarService {
  BaptismCalendarService({FirebaseFirestore? firestore})
      : _entries = (firestore ?? FirebaseFirestore.instance)
            .collection('baptismCalendar');

  final CollectionReference<Map<String, dynamic>> _entries;

  Stream<List<BaptismCalendarEntry>> watchEntries({String? churchId}) {
    final query = churchId != null && churchId.isNotEmpty
        ? _entries.where('churchId', isEqualTo: churchId)
        : _entries.orderBy('baptismDate', descending: false);
    return query.snapshots().map((snapshot) {
      final list =
          snapshot.docs.map(BaptismCalendarEntry.fromFirestore).toList();
      list.sort((a, b) => a.baptismDate.compareTo(b.baptismDate));
      return list;
    });
  }

  Future<String> addEntry(BaptismCalendarEntry entry) async {
    final doc = await _entries.add(entry.toMap());
    return doc.id;
  }

  Future<void> deleteEntry(String id) {
    return _entries.doc(id).delete();
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
