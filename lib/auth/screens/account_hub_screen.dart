import 'package:flutter/material.dart';

import '../../church/screens/register_church_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../models/user_profile.dart';
import 'change_password_screen.dart';
import 'edit_personal_data_screen.dart';

/// Punto de entrada para gestionar la cuenta (formularios separados).
class AccountHubScreen extends StatelessWidget {
  const AccountHubScreen({
    super.key,
    required this.session,
  });

  final UserSession session;

  @override
  Widget build(BuildContext context) {
    final name = session.resolvedDisplayName.isNotEmpty
        ? session.resolvedDisplayName
        : 'Usuario';
    final roles = session.profile.permissions.roleLabels;
    final permissions = session.profile.permissions;
    final churchId = session.profile.churchId;
    final showChurchData = permissions.canManageChurch &&
        churchId != null &&
        churchId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      backgroundColor: AppColors.chatBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (roles.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Roles en el sistema',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roles
                        .map(
                          (label) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bubbleOutgoing,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          if (roles.isNotEmpty)
            const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ColoredBox(
              color: AppColors.surface,
              child: ListView(
                children: [
                  WhatsappListTile(
                    icon: Icons.person_outline,
                    title: 'Datos personales',
                    subtitle: session.isLeaderAccount
                        ? 'Nombre, dirección y teléfono'
                        : 'Nombre de tu perfil',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              EditPersonalDataScreen(session: session),
                        ),
                      );
                    },
                  ),
                  if (showChurchData)
                    WhatsappListTile(
                      icon: Icons.church_outlined,
                      title: 'Datos de la iglesia',
                      subtitle: 'Nombre, dirección y logo de tu sede',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RegisterChurchScreen(
                              updatedBy: session.email,
                              permissions: permissions,
                              churchId: churchId,
                            ),
                          ),
                        );
                      },
                    ),
                  WhatsappListTile(
                    icon: Icons.lock_outline,
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualiza la clave de acceso',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
