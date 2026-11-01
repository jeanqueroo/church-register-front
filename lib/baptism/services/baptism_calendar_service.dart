import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../models/baptism_assigned_member.dart';
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

  Future<void> updateEntry(BaptismCalendarEntry entry) {
    final entryId = entry.id;
    if (entryId == null || entryId.isEmpty) {
      throw ArgumentError('Entry id is required');
    }

    final time = entry.time?.trim();
    final location = entry.location?.trim();
    final notes = entry.notes?.trim();

    return _entries.doc(entryId).update({
      'baptismDate': Timestamp.fromDate(entry.dateOnly),
      if (time != null && time.isNotEmpty)
        'time': time
      else
        'time': FieldValue.delete(),
      if (location != null && location.isNotEmpty)
        'location': location
      else
        'location': FieldValue.delete(),
      if (notes != null && notes.isNotEmpty)
        'notes': notes
      else
        'notes': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAssignedMembers({
    required String entryId,
    required List<BaptismAssignedMember> members,
  }) {
    return _entries.doc(entryId).update({
      'assignedMembers': BaptismAssignedMember.toFirestoreList(members),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
