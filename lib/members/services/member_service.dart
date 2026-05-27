import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/church_member.dart';

class MemberService {
  MemberService({FirebaseFirestore? firestore})
      : _members = (firestore ?? FirebaseFirestore.instance)
            .collection('members');

  final CollectionReference<Map<String, dynamic>> _members;

  Stream<List<ChurchMember>> watchMembers() {
    return _members
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChurchMember.fromFirestore).toList(),
        );
  }

  Future<void> addMember(ChurchMember member) {
    return _members.add(member.toMap());
  }

  Future<void> updateMember(ChurchMember member) {
    final id = member.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('El integrante debe tener id para actualizar');
    }
    return _members.doc(id).update(member.toMap());
  }

  Future<void> deleteMember(String id) {
    return _members.doc(id).delete();
  }

  static String messageFromFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para esta operación.';
      case 'unavailable':
        return 'Firestore no está disponible. Revisa tu conexión.';
      case 'not-found':
        return 'El integrante ya no existe.';
      default:
        return 'Error al procesar la solicitud. Intenta de nuevo.';
    }
  }
}
