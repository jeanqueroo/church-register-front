import 'package:flutter/material.dart';

import '../models/app_user_role.dart';

/// Selección de roles de app para cuentas de líder (chips).
class AssignableRolesSection extends StatelessWidget {
  const AssignableRolesSection({
    super.key,
    required this.selectedRoles,
    required this.onChanged,
    this.enabled = true,
  });

  final Set<String> selectedRoles;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Marca los permisos de acceso en la aplicación. '
          'Puedes combinar Líder y Supervisor en la misma cuenta.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppUserRole.assignableForLeaderRegistration.map((role) {
            final selected = selectedRoles.contains(role);
            return FilterChip(
              label: Text(AppUserRole.label(role)),
              selected: selected,
              onSelected: enabled
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
