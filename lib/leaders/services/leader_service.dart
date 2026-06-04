import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/church_leader.dart';

class LeaderService {
  LeaderService({FirebaseFirestore? firestore})
      : _leaders = (firestore ?? FirebaseFirestore.instance)
            .collection('leaders');

  final CollectionReference<Map<String, dynamic>> _leaders;

  Stream<List<ChurchLeader>> watchLeaders({String? churchId}) {
    final query = churchId != null && churchId.isNotEmpty
        ? _leaders.where('churchId', isEqualTo: churchId)
        : _leaders.orderBy('registeredAt', descending: true);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ChurchLeader.fromFirestore).toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    });
  }

  Future<String> addLeader(ChurchLeader leader) async {
    final doc = await _leaders.add(leader.toMap());
    return doc.id;
  }

  Future<void> updateLeader(ChurchLeader leader) {
    final id = leader.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('El líder debe tener id para actualizar');
    }
    return _leaders.doc(id).set(leader.toMap(), SetOptions(merge: true));
  }

  Future<ChurchLeader?> fetchLeaderByAuthUserId(String authUserId) async {
    final snapshot = await _leaders
        .where('authUserId', isEqualTo: authUserId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ChurchLeader.fromFirestore(snapshot.docs.first);
  }

  Future<void> deleteLeader(String id) {
    return _leaders.doc(id).delete();
  }

  Future<ChurchLeader?> fetchLeaderById(String id) async {
    final doc = await _leaders.doc(id).get();
    if (!doc.exists) return null;
    return ChurchLeader.fromFirestore(doc);
  }

  Future<List<ChurchLeader>> fetchAllLeaders({String? churchId}) async {
    final snapshot = churchId != null && churchId.isNotEmpty
        ? await _leaders.where('churchId', isEqualTo: churchId).get()
        : await _leaders.get();
    return snapshot.docs.map(ChurchLeader.fromFirestore).toList();
  }

  static String messageFromFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para esta operación.';
      case 'unavailable':
        return 'Firestore no está disponible. Revisa tu conexión.';
      case 'not-found':
        return 'El líder ya no existe.';
      default:
        return 'Error al procesar la solicitud. Intenta de nuevo.';
    }
  }
}
