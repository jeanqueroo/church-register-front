import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../models/cell_disciple.dart';
import '../models/cell_disciple_selection.dart';
import '../models/cell_helper.dart';
import '../models/church_cell.dart';

class CellService {
  CellService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _cells = (firestore ?? FirebaseFirestore.instance).collection('cells'),
        _unassignedDisciples =
            (firestore ?? FirebaseFirestore.instance).collection('disciples');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _cells;
  final CollectionReference<Map<String, dynamic>> _unassignedDisciples;

  Stream<List<ChurchCell>> watchCells({String? churchId}) {
    final query = churchId != null && churchId.isNotEmpty
        ? _cells.where('churchId', isEqualTo: churchId)
        : _cells.orderBy('registeredAt', descending: true);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ChurchCell.fromFirestore).toList();
      list.sort((a, b) => a.code.compareTo(b.code));
      return list;
    });
  }

  Future<String> addCell(ChurchCell cell) async {
    final doc = await _cells.add(cell.toMap());
    return doc.id;
  }

  Future<void> updateCell({
    required String cellId,
    required ChurchCell cell,
    String? previousCode,
  }) async {
    await _cells.doc(cellId).set(
      cell.toMap(clearLegacyAlias: true),
      SetOptions(merge: true),
    );

    final newCode = cell.code.trim();
    final oldCode = previousCode?.trim() ?? '';
    if (newCode.isNotEmpty && newCode != oldCode) {
      await updateDisciplesCellCode(cellId: cellId, cellCode: newCode);
    }
  }

  Future<void> updateDisciplesCellCode({
    required String cellId,
    required String cellCode,
  }) async {
    final snapshot = await _cells.doc(cellId).collection('disciples').get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'cellCode': cellCode,
        'cellId': cellId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<ChurchCell?> fetchCellById(String id) async {
    final doc = await _cells.doc(id).get();
    if (!doc.exists) return null;
    return ChurchCell.fromFirestore(doc);
  }

  Future<void> adjustMemberCount(String cellId, int delta) async {
    if (cellId.trim().isEmpty || delta == 0) return;
    await _cells.doc(cellId).set(
      {
        'memberCount': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<ChurchCell?> watchCellById(String id) {
    return _cells.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChurchCell.fromFirestore(doc);
    });
  }

  Future<void> updateCellHelpers({
    required String cellId,
    required List<CellHelper> helpers,
  }) async {
    if (helpers.length > ChurchCell.maxHelpers) {
      throw ArgumentError('Máximo ${ChurchCell.maxHelpers} asistentes por célula');
    }
    await _cells.doc(cellId).update({
      'helpers': helpers.map((helper) => helper.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCellBlocked({
    required String cellId,
    required bool blocked,
  }) async {
    await _cells.doc(cellId).update({
      'isBlocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Leader IDs that already lead a cell (optionally scoped to [churchId]).
  /// Pass [excludeCellId] when editing so the current cell's leader stays selectable.
  Future<Set<String>> fetchLeaderIdsWithAssignedCell({
    String? churchId,
    String? excludeCellId,
  }) async {
    Query<Map<String, dynamic>> query = _cells;
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }
    final snapshot = await query.get();
    final leaderIds = <String>{};
    for (final doc in snapshot.docs) {
      if (excludeCellId != null && doc.id == excludeCellId) continue;
      final leaderId = (doc.data()['leaderId'] as String? ?? '').trim();
      if (leaderId.isNotEmpty) leaderIds.add(leaderId);
    }
    return leaderIds;
  }

  Future<List<ChurchCell>> fetchCellsForChurch(String churchId) async {
    if (churchId.isEmpty) return [];

    final snapshot =
        await _cells.where('churchId', isEqualTo: churchId).get();
    final list = snapshot.docs.map(ChurchCell.fromFirestore).toList();
    list.sort((a, b) => a.code.compareTo(b.code));
    return list;
  }

  Future<List<ChurchCell>> fetchCellsForLeaderIds({
    required List<String> leaderIds,
    String? churchId,
  }) async {
    if (leaderIds.isEmpty) return [];

    final uniqueIds = leaderIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) return [];

    final result = <ChurchCell>[];
    final seenIds = <String>{};

    final snapshots = await Future.wait(
      uniqueIds.map(
        (leaderId) => _cells.where('leaderId', isEqualTo: leaderId).get(),
      ),
    );

    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        if (seenIds.contains(doc.id)) continue;
        final cell = ChurchCell.fromFirestore(doc);
        if (cell.isBlocked) continue;
        if (churchId != null &&
            churchId.isNotEmpty &&
            cell.churchId != null &&
            cell.churchId!.isNotEmpty &&
            cell.churchId != churchId) {
          continue;
        }
        seenIds.add(doc.id);
        result.add(cell);
      }
    }

    result.sort((a, b) => a.code.compareTo(b.code));
    return result;
  }

  /// Código de célula por `leaderId` (líder titular de la célula).
  Future<Map<String, String>> fetchCellCodeByLeaderId({String? churchId}) async {
    Query<Map<String, dynamic>> query = _cells;
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }

    final snapshot = await query.get();
    final map = <String, String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final leaderId = (data['leaderId'] as String? ?? '').trim();
      final code = (data['code'] as String? ?? '').trim();
      if (leaderId.isEmpty || code.isEmpty) continue;

      final existing = map[leaderId];
      map[leaderId] = existing == null ? code : '$existing, $code';
    }

    return map;
  }

  Stream<List<ChurchCell>> watchCellsForLeaderId(String leaderId) {
    return _cells
        .where('leaderId', isEqualTo: leaderId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(ChurchCell.fromFirestore).toList();
      list.sort((a, b) => a.code.compareTo(b.code));
      return list;
    });
  }

  Stream<List<CellDisciple>> watchDisciples(String cellId) {
    return _cells
        .doc(cellId)
        .collection('disciples')
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CellDisciple.fromFirestore(doc, cellId: cellId))
              .toList(),
        );
  }

  Future<String> addDisciple(CellDisciple disciple) async {
    final doc = await _cells
        .doc(disciple.cellId)
        .collection('disciples')
        .add(disciple.toMap());
    return doc.id;
  }

  Future<String> addUnassignedDisciple(CellDisciple disciple) async {
    final doc = await _unassignedDisciples.add(disciple.toUnassignedMap());
    return doc.id;
  }

  Future<void> deleteDisciple({
    required String cellId,
    required String discipleId,
  }) {
    return _cells.doc(cellId).collection('disciples').doc(discipleId).delete();
  }

  Future<List<ChurchDiscipleEntry>> fetchUnassignedDisciples({
    String? churchId,
  }) async {
    if (churchId == null || churchId.isEmpty) {
      return [];
    }

    final snapshot = await _unassignedDisciples
        .where('churchId', isEqualTo: churchId)
        .where('assigned', isEqualTo: false)
        .get();

    final entries = snapshot.docs
        .map(
          (doc) => ChurchDiscipleEntry(
            id: doc.id,
            disciple: CellDisciple.fromRootFirestore(doc),
          ),
        )
        .where((entry) => !entry.disciple.isAssignedToCell)
        .toList();

    entries.sort(
      (a, b) => a.disciple.fullName.compareTo(b.disciple.fullName),
    );
    return entries;
  }

  Future<void> assignUnassignedDiscipleToCell({
    required String unassignedDiscipleId,
    required String cellId,
    required String cellCode,
    String? churchId,
  }) async {
    final poolRef = _unassignedDisciples.doc(unassignedDiscipleId);
    final snapshot = await poolRef.get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Disciple not found',
      );
    }

    final data = Map<String, dynamic>.from(snapshot.data()!);
    if (data['assigned'] == true || (data['cellId'] as String? ?? '').isNotEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'failed-precondition',
        message: 'Disciple already assigned to a cell',
      );
    }

    if (churchId != null && churchId.isNotEmpty) {
      final discipleChurchId = data['churchId'] as String? ?? '';
      if (discipleChurchId.isNotEmpty && discipleChurchId != churchId) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Disciple belongs to another church',
        );
      }
    }

    data['cellId'] = cellId;
    data['cellCode'] = cellCode;
    if (churchId != null && churchId.isNotEmpty) {
      data['churchId'] = churchId;
    }
    data.remove('assigned');
    data['updatedAt'] = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    final cellRef = _cells.doc(cellId).collection('disciples').doc();
    batch.set(cellRef, data);
    batch.delete(poolRef);
    await batch.commit();
  }

  Future<bool> codeExists({
    required String code,
    String? churchId,
    String? excludeId,
  }) async {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    Query<Map<String, dynamic>> query = _cells;
    if (churchId != null && churchId.isNotEmpty) {
      query = query.where('churchId', isEqualTo: churchId);
    }
    final snapshot = await query.get();
    for (final doc in snapshot.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      final existing = (doc.data()['code'] as String? ?? '').trim().toLowerCase();
      if (existing == normalized) return true;
    }
    return false;
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
