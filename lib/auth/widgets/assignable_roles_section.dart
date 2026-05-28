import 'package:flutter/material.dart';

import '../../core/widgets/form_section_title.dart';
import '../models/app_user_role.dart';

/// Selector de roles al registrar o editar un líder (sin administrador).
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

  void _toggleRole(String role, bool selected) {
    if (!enabled) return;

    final next = Set<String>.from(selectedRoles);
    if (selected) {
      next.add(role);
    } else {
      next.remove(role);
    }
    onChanged(AppUserRole.sanitizeForLeaderRegistration(next).toSet());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormSectionTitle('ROLES EN LA APP'),
        Text(
          'Elige qué puede hacer esta cuenta. El rol Administrador solo se '
          'asigna desde Firebase Console.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppUserRole.assignableForLeaderRegistration.map((role) {
            return FilterChip(
              label: Text(AppUserRole.label(role)),
              selected: selectedRoles.contains(role),
              onSelected: enabled ? (value) => _toggleRole(role, value) : null,
              showCheckmark: true,
            );
          }).toList(),
        ),
        if (selectedRoles.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selecciona al menos un rol.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}
