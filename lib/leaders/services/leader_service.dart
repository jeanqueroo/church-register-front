import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/church_leader.dart';

class LeaderService {
  LeaderService({FirebaseFirestore? firestore})
      : _leaders = (firestore ?? FirebaseFirestore.instance)
            .collection('leaders');

  final CollectionReference<Map<String, dynamic>> _leaders;

  Stream<List<ChurchLeader>> watchLeaders() {
    return _leaders
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChurchLeader.fromFirestore).toList(),
        );
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
    return _leaders.doc(id).update(leader.toMap());
  }

  Future<void> deleteLeader(String id) {
    return _leaders.doc(id).delete();
  }

  Future<ChurchLeader?> fetchLeaderById(String id) async {
    final doc = await _leaders.doc(id).get();
    if (!doc.exists) return null;
    return ChurchLeader.fromFirestore(doc);
  }

  Future<List<ChurchLeader>> fetchAllLeaders() async {
    final snapshot = await _leaders.get();
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
