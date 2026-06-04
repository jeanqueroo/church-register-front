import 'package:flutter/material.dart';

import '../models/access_block.dart';
import '../services/auth_service.dart';

/// Pantalla cuando la cuenta o la iglesia asignada está bloqueada.
class BlockedAccountScreen extends StatelessWidget {
  const BlockedAccountScreen({
    super.key,
    required this.authService,
    required this.block,
  });

  final AuthService authService;
  final AccessBlock block;

  String get _title {
    switch (block.kind) {
      case AccessBlockKind.user:
        return 'Cuenta bloqueada';
      case AccessBlockKind.church:
        return 'Iglesia bloqueada';
    }
  }

  String get _message {
    switch (block.kind) {
      case AccessBlockKind.user:
        return 'Tu usuario fue suspendido. '
            'Contacta al super administrador para reactivar tu acceso.';
      case AccessBlockKind.church:
        return 'La iglesia asignada a tu cuenta está bloqueada. '
            'No puedes usar el sistema hasta que el super administrador la reactive.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: authService.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
