import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../models/app_user_role.dart';

/// Selección de roles de app para cuentas de líder (chips).
class AssignableRolesSection extends StatelessWidget {
  const AssignableRolesSection({
    super.key,
    required this.selectedRoles,
    required this.onChanged,
    this.enabled = true,
    this.allowedRoles,
  });

  final Set<String> selectedRoles;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;
  final List<String>? allowedRoles;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final registrarSelected =
        selectedRoles.contains(AppUserRole.registrar);
    final roles = allowedRoles ?? AppUserRole.assignableForLeaderRegistration;
    final registrarOnly =
        allowedRoles != null &&
        allowedRoles!.length == 1 &&
        allowedRoles!.first == AppUserRole.registrar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          registrarOnly
              ? l10n.assignableRolesVolunteerOnly
              : registrarSelected
                  ? l10n.assignableRolesRegistrarExclusive
                  : l10n.assignableRolesHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final selected = selectedRoles.contains(role);
            final roleDisabled = registrarSelected && role != AppUserRole.registrar;
            return FilterChip(
              label: Text(AppUserRole.localizedLabel(role, l10n)),
              selected: selected,
              onSelected: enabled && !roleDisabled
                  ? (value) {
                      final next = Set<String>.from(selectedRoles);
                      if (value) {
                        next.add(role);
                      } else {
                        next.remove(role);
                      }
                      onChanged(
                        AppUserRole.sanitizeForLeaderRegistration(next).toSet(),
                      );
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}
