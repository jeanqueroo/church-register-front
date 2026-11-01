import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../l10n/app_localizations.dart';
import '../../firebase_options.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Crea un usuario Auth sin cerrar la sesión del administrador actual.
  ///
  /// Usa una instancia secundaria de Firebase. No se elimina la app secundaria
  /// al terminar: borrarla provoca crash en hilos de Auth en background.
  Future<UserCredential> createLeaderAccount({
    required String email,
    required String password,
  }) async {
    final appName = 'LeaderRegistration_${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await secondaryAuth.signOut();
    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  static String messageFromFirebaseAuthException(
    FirebaseAuthException e,
    AppLocalizations l10n,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return l10n.authInvalidEmail;
      case 'user-disabled':
        return l10n.authUserDisabled;
      case 'user-not-found':
        return l10n.authUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.authWrongPassword;
      case 'email-already-in-use':
        return l10n.authEmailInUse;
      case 'weak-password':
        return l10n.authWeakPassword;
      case 'requires-recent-login':
        return l10n.authRequiresRecentLogin;
      case 'too-many-requests':
        return l10n.authTooManyRequests;
      case 'network-request-failed':
        return l10n.authNetworkError;
      case 'operation-not-allowed':
        return l10n.authOperationNotAllowed;
      default:
        return l10n.authGenericError;
    }
  }
}
