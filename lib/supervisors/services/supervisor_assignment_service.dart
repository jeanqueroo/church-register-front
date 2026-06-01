import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/app_user_role.dart';
import '../models/supervisor_account.dart';

class SupervisorAssignmentService {
  SupervisorAssignmentService({FirebaseFirestore? firestore})
      : _users = (firestore ?? FirebaseFirestore.instance).collection('users');

  final CollectionReference<Map<String, dynamic>> _users;

  Stream<List<String>> watchSupervisedLeaderIds(String supervisorUid) {
    return _users.doc(supervisorUid).snapshots().map((doc) {
      return _parseLeaderIds(doc.data()?['supervisedLeaderIds']);
    });
  }

  Future<List<SupervisorAccount>> fetchSupervisorAccounts() async {
    final snapshot = await _users
        .where('roles', arrayContains: AppUserRole.supervisor)
        .get();

    final accounts = snapshot.docs.map(_supervisorFromDoc).toList();
    accounts.sort(
      (a, b) => a.displayLabel.toLowerCase().compareTo(
            b.displayLabel.toLowerCase(),
          ),
    );
    return accounts;
  }

  Future<void> setSupervisedLeaderIds({
    required String supervisorUid,
    required List<String> leaderIds,
  }) {
    return _users.doc(supervisorUid).set(
      {
        'supervisedLeaderIds': leaderIds,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  SupervisorAccount _supervisorFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SupervisorAccount(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String?,
      supervisedLeaderIds: _parseLeaderIds(data['supervisedLeaderIds']),
    );
  }

  List<String> _parseLeaderIds(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
  }

  static String messageFromFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para esta operación. '
            'Confirma que tu usuario en Firestore (colección users) tiene '
            'roles admin y/o supervisor, y publica firestore.rules '
            '(firebase deploy --only firestore:rules).';
      case 'unavailable':
        return 'Firestore no está disponible. Revisa tu conexión.';
      default:
        return 'Error al guardar las asignaciones. Intenta de nuevo.';
    }
  }
}
