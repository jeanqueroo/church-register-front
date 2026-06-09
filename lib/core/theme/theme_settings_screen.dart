import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../locale/l10n_extensions.dart';
import '../widgets/whatsapp_list_tile.dart';
import 'theme_controller.dart';
import 'theme_templates.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.churchPalette;
    final controller = AppThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeSettingsTitle)),
      backgroundColor: palette.scaffoldBackground,
      body: ColoredBox(
        color: palette.surface,
        child: ListView(
          children: [
            _SectionHeader(title: l10n.themeColorSection),
            ...kThemeTemplates.map(
              (template) => _TemplateTile(
                template: template,
                title: _templateTitle(l10n, template.id),
                subtitle: _templateSubtitle(l10n, template.id),
                selected: controller.templateId == template.id,
                onTap: () => controller.setTemplateId(template.id),
                showDivider: template.id != ThemeTemplateIds.traditional,
              ),
            ),
            const SizedBox(height: 8),
            _SectionHeader(title: l10n.themeModeSection),
            _ModeTile(
              title: l10n.themeSystem,
              subtitle: l10n.themeSystemSubtitle,
              selected: controller.preference == ThemeController.preferenceSystem,
              onTap: () =>
                  controller.setPreference(ThemeController.preferenceSystem),
            ),
            _ModeTile(
              title: l10n.themeLight,
              selected: controller.preference == ThemeController.preferenceLight,
              onTap: () =>
                  controller.setPreference(ThemeController.preferenceLight),
            ),
            _ModeTile(
              title: l10n.themeDark,
              selected: controller.preference == ThemeController.preferenceDark,
              onTap: () =>
                  controller.setPreference(ThemeController.preferenceDark),
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  String _templateTitle(AppLocalizations l10n, String id) {
    switch (id) {
      case ThemeTemplateIds.manantial:
        return l10n.templateManantial;
      case ThemeTemplateIds.whatsapp:
        return l10n.templateWhatsapp;
      case ThemeTemplateIds.peace:
        return l10n.templatePeace;
      case ThemeTemplateIds.traditional:
        return l10n.templateTraditional;
      default:
        return id;
    }
  }

  String _templateSubtitle(AppLocalizations l10n, String id) {
    switch (id) {
      case ThemeTemplateIds.manantial:
        return l10n.templateManantialSubtitle;
      case ThemeTemplateIds.whatsapp:
        return l10n.templateWhatsappSubtitle;
      case ThemeTemplateIds.peace:
        return l10n.templatePeaceSubtitle;
      case ThemeTemplateIds.traditional:
        return l10n.templateTraditionalSubtitle;
      default:
        return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final ThemeTemplate template;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.churchPalette;
    return WhatsappListTile(
      icon: Icons.color_lens_outlined,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      showDivider: showDivider,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorSwatch(color: template.light.primary),
          const SizedBox(width: 4),
          _ColorSwatch(color: template.light.accent),
          const SizedBox(width: 8),
          if (selected)
            Icon(Icons.check_circle, color: palette.primary)
          else
            const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
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
    final palette = context.churchPalette;
    return WhatsappListTile(
      icon: Icons.brightness_6_outlined,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      showDivider: showDivider,
      trailing: selected
          ? Icon(Icons.check_circle, color: palette.primary)
          : null,
    );
  }
}
