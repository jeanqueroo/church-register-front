import 'package:church_register/auth/screens/login_screen.dart';
import 'package:church_register/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);
}

void main() {
  setUpAll(() {
    setupFirebaseCoreMocks();
  });

  testWidgets('Login screen shows title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authService: AuthService(firebaseAuth: _MockFirebaseAuth()),
        ),
      ),
    );

    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
