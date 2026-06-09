import 'package:flutter/material.dart';

/// Colores semánticos de la app (claro / oscuro) vía [ThemeExtension].
@immutable
class ChurchPalette extends ThemeExtension<ChurchPalette> {
  const ChurchPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.accentDark,
    required this.scaffoldBackground,
    required this.surface,
    required this.textSecondary,
    required this.divider,
    required this.bubbleOutgoing,
    required this.selectedTile,
    required this.drawerBackground,
    required this.onSurface,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;
  final Color accentDark;
  final Color scaffoldBackground;
  final Color surface;
  final Color textSecondary;
  final Color divider;
  final Color bubbleOutgoing;
  final Color selectedTile;
  final Color drawerBackground;
  final Color onSurface;

  @override
  ChurchPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? accent,
    Color? accentDark,
    Color? scaffoldBackground,
    Color? surface,
    Color? textSecondary,
    Color? divider,
    Color? bubbleOutgoing,
    Color? selectedTile,
    Color? drawerBackground,
    Color? onSurface,
  }) {
    return ChurchPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      surface: surface ?? this.surface,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      bubbleOutgoing: bubbleOutgoing ?? this.bubbleOutgoing,
      selectedTile: selectedTile ?? this.selectedTile,
      drawerBackground: drawerBackground ?? this.drawerBackground,
      onSurface: onSurface ?? this.onSurface,
    );
  }

  @override
  ChurchPalette lerp(ThemeExtension<ChurchPalette>? other, double t) {
    if (other is! ChurchPalette) return this;
    return ChurchPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      scaffoldBackground:
          Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      bubbleOutgoing: Color.lerp(bubbleOutgoing, other.bubbleOutgoing, t)!,
      selectedTile: Color.lerp(selectedTile, other.selectedTile, t)!,
      drawerBackground: Color.lerp(drawerBackground, other.drawerBackground, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
    );
  }
}
