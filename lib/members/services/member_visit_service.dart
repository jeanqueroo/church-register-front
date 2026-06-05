import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member_visit.dart';

class MemberVisitService {
  MemberVisitService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _visits(String memberId) {
    return _firestore.collection('members').doc(memberId).collection('visits');
  }

  Stream<List<MemberVisit>> watchVisits(String memberId) {
    return _visits(memberId)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(MemberVisit.fromFirestore).toList(),
        );
  }

  Future<void> addVisit(MemberVisit visit) async {
    final memberId = visit.memberId.trim();
    if (memberId.isEmpty) {
      throw ArgumentError('El integrante debe tener id');
    }
    if (visit.comment.trim().isEmpty) {
      throw ArgumentError('El comentario es obligatorio');
    }
    await _visits(memberId).add(visit.toMap());
  }

  static String messageFromFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para registrar visitas.';
      case 'unavailable':
        return 'Servicio no disponible. Revisa tu conexión.';
      default:
        return 'Error al guardar la visita. Intenta de nuevo.';
    }
  }
}
