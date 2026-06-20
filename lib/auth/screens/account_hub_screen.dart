import 'package:flutter/material.dart';

import '../../church/screens/register_church_screen.dart';
import '../../core/locale/language_settings_screen.dart';
import '../../core/locale/l10n_extensions.dart';
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
    final l10n = context.l10n;
    final palette = context.churchPalette;
    final name = session.resolvedDisplayName.isNotEmpty
        ? session.resolvedDisplayName
        : l10n.user;
    final roles = session.profile.permissions.roleLabelsFor(l10n);
    final permissions = session.profile.permissions;
    final churchId = session.profile.churchId;
    final showChurchData = permissions.canViewChurchData;
    final editsFullPersonalData = session.isLeaderAccount ||
        permissions.isRegistrar ||
        permissions.isSupervisor;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAccount)),
      backgroundColor: palette.scaffoldBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            color: palette.primary,
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
              color: palette.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.systemRoles,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: palette.textSecondary,
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
                              color: palette.bubbleOutgoing,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: palette.primaryDark,
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
            Divider(height: 1, color: palette.divider),
          Expanded(
            child: ColoredBox(
              color: palette.surface,
              child: ListView(
                children: [
                  WhatsappListTile(
                    icon: Icons.person_outline,
                    title: l10n.personalData,
                    subtitle: editsFullPersonalData
                        ? l10n.personalDataSubtitleFull
                        : l10n.personalDataSubtitleName,
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
                      title: l10n.churchData,
                      subtitle: l10n.churchDataSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RegisterChurchScreen(
                              updatedBy: session.email,
                              permissions: permissions,
                              churchId: churchId,
                              readOnly: true,
                            ),
                          ),
                        );
                      },
                    ),
                  WhatsappListTile(
                    icon: Icons.lock_outline,
                    title: l10n.changePassword,
                    subtitle: l10n.changePasswordSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  WhatsappListTile(
                    icon: Icons.translate_outlined,
                    title: l10n.language,
                    subtitle: l10n.languageSubtitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LanguageSettingsScreen(),
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
