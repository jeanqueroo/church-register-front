import 'package:flutter/material.dart';

import 'church_palette.dart';

/// Plantillas de color de la app. Cambia la predeterminada en [defaultTemplateId].
class ThemeTemplate {
  const ThemeTemplate({
    required this.id,
    required this.light,
    required this.dark,
  });

  final String id;
  final ChurchPalette light;
  final ChurchPalette dark;

  ChurchPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Identificadores guardados en preferencias.
abstract final class ThemeTemplateIds {
  static const manantial = 'manantial';
  static const whatsapp = 'whatsapp';
  static const peace = 'paz';
  static const traditional = 'tradicional';

  static const all = [manantial, whatsapp, peace, traditional];
}

/// **Recomendada:** azul profundo + dorado — agua, bendición, seriedad pastoral.
const ThemeTemplate manantialTemplate = ThemeTemplate(
  id: ThemeTemplateIds.manantial,
  light: ChurchPalette(
    primary: Color(0xFF1B3A5C),
    primaryDark: Color(0xFF0F2438),
    primaryLight: Color(0xFF2E5A87),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFFF5F3EF),
    surface: Colors.white,
    textSecondary: Color(0xFF5C6B7A),
    divider: Color(0xFFE4E0D8),
    bubbleOutgoing: Color(0xFFE3EBF5),
    selectedTile: Color(0xFFEDEAE4),
    drawerBackground: Colors.white,
    onSurface: Color(0xFF1A2332),
  ),
  dark: ChurchPalette(
    primary: Color(0xFF3D6A9E),
    primaryDark: Color(0xFF1B3A5C),
    primaryLight: Color(0xFF5B8BC4),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFF0D1117),
    surface: Color(0xFF1A2332),
    textSecondary: Color(0xFF9AA8B8),
    divider: Color(0xFF2A3544),
    bubbleOutgoing: Color(0xFF243448),
    selectedTile: Color(0xFF243448),
    drawerBackground: Color(0xFF141C28),
    onSurface: Color(0xFFE8ECF1),
  ),
);

/// Estilo WhatsApp — verde teal (plantilla anterior).
const ThemeTemplate whatsappTemplate = ThemeTemplate(
  id: ThemeTemplateIds.whatsapp,
  light: ChurchPalette(
    primary: Color(0xFF075E54),
    primaryDark: Color(0xFF054D45),
    primaryLight: Color(0xFF128C7E),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFFECE5DD),
    surface: Colors.white,
    textSecondary: Color(0xFF667781),
    divider: Color(0xFFE9EDEF),
    bubbleOutgoing: Color(0xFFDCF8C6),
    selectedTile: Color(0xFFF0F2F5),
    drawerBackground: Colors.white,
    onSurface: Color(0xFF111B21),
  ),
  dark: ChurchPalette(
    primary: Color(0xFF128C7E),
    primaryDark: Color(0xFF075E54),
    primaryLight: Color(0xFF25D366),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFF0B141A),
    surface: Color(0xFF1F2C34),
    textSecondary: Color(0xFF8696A0),
    divider: Color(0xFF2A3942),
    bubbleOutgoing: Color(0xFF056162),
    selectedTile: Color(0xFF2A3942),
    drawerBackground: Color(0xFF111B21),
    onSurface: Color(0xFFE9EDEF),
  ),
);

/// Índigo + teal — calmado y moderno.
const ThemeTemplate peaceTemplate = ThemeTemplate(
  id: ThemeTemplateIds.peace,
  light: ChurchPalette(
    primary: Color(0xFF3949AB),
    primaryDark: Color(0xFF283593),
    primaryLight: Color(0xFF5C6BC0),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFFF0F2F8),
    surface: Colors.white,
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE5E7EB),
    bubbleOutgoing: Color(0xFFE8EAF6),
    selectedTile: Color(0xFFEEF0F6),
    drawerBackground: Colors.white,
    onSurface: Color(0xFF1F2937),
  ),
  dark: ChurchPalette(
    primary: Color(0xFF7986CB),
    primaryDark: Color(0xFF3949AB),
    primaryLight: Color(0xFF9FA8DA),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFF12141C),
    surface: Color(0xFF1E2230),
    textSecondary: Color(0xFF9CA3AF),
    divider: Color(0xFF2D3344),
    bubbleOutgoing: Color(0xFF2A3050),
    selectedTile: Color(0xFF2A3050),
    drawerBackground: Color(0xFF181C28),
    onSurface: Color(0xFFE5E7EB),
  ),
);

/// Vino + dorado — tradicional y elegante.
const ThemeTemplate traditionalTemplate = ThemeTemplate(
  id: ThemeTemplateIds.traditional,
  light: ChurchPalette(
    primary: Color(0xFF7B2D42),
    primaryDark: Color(0xFF5C2132),
    primaryLight: Color(0xFF9E4560),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFFFAF6F0),
    surface: Colors.white,
    textSecondary: Color(0xFF6D5E5E),
    divider: Color(0xFFE8E0D8),
    bubbleOutgoing: Color(0xFFF5E8EC),
    selectedTile: Color(0xFFF3EDE6),
    drawerBackground: Colors.white,
    onSurface: Color(0xFF2C2224),
  ),
  dark: ChurchPalette(
    primary: Color(0xFFB85C75),
    primaryDark: Color(0xFF7B2D42),
    primaryLight: Color(0xFFD47A92),
    accent: kPositiveActionColor,
    accentDark: kPositiveActionColorDark,
    scaffoldBackground: Color(0xFF141012),
    surface: Color(0xFF241C1F),
    textSecondary: Color(0xFFA89A9C),
    divider: Color(0xFF3A3034),
    bubbleOutgoing: Color(0xFF3A2830),
    selectedTile: Color(0xFF3A3034),
    drawerBackground: Color(0xFF1C1618),
    onSurface: Color(0xFFF5EDE8),
  ),
);

const String defaultTemplateId = ThemeTemplateIds.manantial;

const List<ThemeTemplate> kThemeTemplates = [
  manantialTemplate,
  whatsappTemplate,
  peaceTemplate,
  traditionalTemplate,
];

ThemeTemplate themeTemplateById(String id) {
  for (final template in kThemeTemplates) {
    if (template.id == id) return template;
  }
  return manantialTemplate;
}

extension ChurchPaletteContext on BuildContext {
  ChurchPalette get churchPalette =>
      Theme.of(this).extension<ChurchPalette>() ?? manantialTemplate.light;
}
