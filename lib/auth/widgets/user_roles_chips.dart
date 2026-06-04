import 'package:flutter/material.dart';

import '../models/app_user_role.dart';

/// Etiquetas de roles de app para listas y detalle de líderes.
class UserRolesChips extends StatelessWidget {
  const UserRolesChips({
    super.key,
    required this.roles,
    this.emptyLabel = 'Sin rol en la app',
  });

  final List<String> roles;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return Text(
        emptyLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: roles.map((role) {
        return Chip(
          label: Text(
            AppUserRole.label(role),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

String appRolesSearchText(List<String> roles) {
  return roles.map(AppUserRole.label).join(' ');
}
