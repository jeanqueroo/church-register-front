import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../models/app_permissions.dart';

/// Pantalla de acceso denegado cuando el rol no permite la vista.
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accessDeniedTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                message ?? l10n.accessDeniedDefault,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Envuelve una pantalla y la bloquea si [allowed] es false.
class RoleGate extends StatelessWidget {
  const RoleGate({
    super.key,
    required this.permissions,
    required this.allowed,
    required this.child,
    this.deniedMessage,
  });

  final AppPermissions permissions;
  final bool allowed;
  final Widget child;
  final String? deniedMessage;

  @override
  Widget build(BuildContext context) {
    if (allowed) return child;
    return AccessDeniedScreen(message: deniedMessage);
  }
}
