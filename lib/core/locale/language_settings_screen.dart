import 'package:flutter/material.dart';

import '../../core/locale/locale_controller.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/whatsapp_list_tile.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = AppLocaleScope.of(context);
    final selected = controller.preference;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettingsTitle)),
      backgroundColor: AppColors.chatBackground,
      body: ColoredBox(
        color: AppColors.surface,
        child: ListView(
          children: [
            _LanguageTile(
              title: l10n.languageSystem,
              subtitle: l10n.languageSystemSubtitle,
              selected: selected == LocaleController.preferenceSystem,
              onTap: () =>
                  controller.setPreference(LocaleController.preferenceSystem),
            ),
            _LanguageTile(
              title: l10n.languageSpanish,
              selected: selected == LocaleController.preferenceSpanish,
              onTap: () =>
                  controller.setPreference(LocaleController.preferenceSpanish),
            ),
            _LanguageTile(
              title: l10n.languageEnglish,
              selected: selected == LocaleController.preferenceEnglish,
              onTap: () =>
                  controller.setPreference(LocaleController.preferenceEnglish),
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return WhatsappListTile(
      icon: Icons.translate_outlined,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      showDivider: showDivider,
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }
}
