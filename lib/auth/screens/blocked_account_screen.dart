import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
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

  String _title(AppLocalizations l10n) {
    switch (block.kind) {
      case AccessBlockKind.user:
        return l10n.blockedAccountUserTitle;
      case AccessBlockKind.church:
        return l10n.blockedAccountChurchTitle;
    }
  }

  String _message(AppLocalizations l10n) {
    switch (block.kind) {
      case AccessBlockKind.user:
        return l10n.blockedAccountUserMessage;
      case AccessBlockKind.church:
        return l10n.blockedAccountChurchMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                  _title(l10n),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _message(l10n),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: authService.signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
