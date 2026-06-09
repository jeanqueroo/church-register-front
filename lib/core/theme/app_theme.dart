import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'church_palette.dart';

export 'church_palette.dart';
export 'theme_templates.dart';

/// Nombre visible de la aplicación.
const String appDisplayName = 'Manantial de Bendiciones';

/// Paleta clara (legacy). Para tema dinámico usa [ChurchPalette] / [ChurchPaletteContext].
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF075E54);
  static const Color primaryDark = Color(0xFF054D45);
  static const Color primaryLight = Color(0xFF128C7E);
  static const Color accent = Color(0xFF25D366);
  static const Color accentDark = Color(0xFF1DA851);
  static const Color chatBackground = Color(0xFFECE5DD);
  static const Color surface = Colors.white;
  static const Color textSecondary = Color(0xFF667781);
  static const Color divider = Color(0xFFE9EDEF);
  static const Color bubbleOutgoing = Color(0xFFDCF8C6);
  static const Color selectedTile = Color(0xFFF0F2F5);
  static const Color drawerBackground = surface;
  static const Color onSurface = Color(0xFF111B21);
}

ColorScheme _churchColorScheme(ChurchPalette palette, Brightness brightness) {
  return ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: brightness,
    primary: palette.primary,
    onPrimary: Colors.white,
    primaryContainer: palette.bubbleOutgoing,
    onPrimaryContainer: palette.primaryDark,
    secondary: palette.accent,
    onSecondary: Colors.white,
    secondaryContainer: brightness == Brightness.light
        ? const Color(0xFFD7F5E3)
        : const Color(0xFF0D4D3D),
    onSecondaryContainer: palette.accentDark,
    surface: palette.surface,
    onSurface: palette.onSurface,
    onSurfaceVariant: palette.textSecondary,
    outline: palette.divider,
    outlineVariant: brightness == Brightness.light
        ? const Color(0xFFD1D7DB)
        : const Color(0xFF3B4A54),
    surfaceContainerHighest: palette.selectedTile,
  );
}

TextTheme _churchTextTheme(TextTheme base, ChurchPalette palette) {
  return GoogleFonts.interTextTheme(base).apply(
    bodyColor: palette.onSurface,
    displayColor: palette.onSurface,
  );
}

/// Tema Cupertino alineado con la marca (widgets iOS dentro de MaterialApp).
CupertinoThemeData buildChurchCupertinoTheme({
  required Brightness brightness,
  required ChurchPalette palette,
}) {
  final base = CupertinoThemeData(brightness: brightness);
  final inter = GoogleFonts.inter;

  return base.copyWith(
    primaryColor: palette.primary,
    primaryContrastingColor: Colors.white,
    scaffoldBackgroundColor: palette.scaffoldBackground,
    barBackgroundColor: palette.primary.withValues(alpha: 0.97),
    brightness: brightness,
    textTheme: CupertinoTextThemeData(
      textStyle: inter(
        fontSize: 17,
        color: palette.onSurface,
        letterSpacing: -0.41,
      ),
      actionTextStyle: inter(
        fontSize: 17,
        color: palette.primaryLight,
        fontWeight: FontWeight.w600,
      ),
      navTitleTextStyle: inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      navLargeTitleTextStyle: inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: palette.onSurface,
        letterSpacing: 0.37,
      ),
      pickerTextStyle: inter(
        fontSize: 22,
        color: palette.onSurface,
      ),
      tabLabelTextStyle: inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
    ),
  );
}

ThemeData _buildChurchTheme({
  required Brightness brightness,
  required ChurchPalette palette,
}) {
  final colorScheme = _churchColorScheme(palette, brightness);
  final isDark = brightness == Brightness.dark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    cupertinoOverrideTheme: buildChurchCupertinoTheme(
      brightness: brightness,
      palette: palette,
    ),
    extensions: [palette],
  );
  final textTheme = _churchTextTheme(base.textTheme, palette);

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: _churchTextTheme(base.primaryTextTheme, palette),
    scaffoldBackgroundColor: palette.scaffoldBackground,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: palette.primary,
      foregroundColor: Colors.white,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: palette.primaryDark,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 64,
      backgroundColor: palette.surface,
      indicatorColor: palette.bubbleOutgoing,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? palette.primary : palette.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.primary : palette.textSecondary,
        );
      }),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: palette.drawerBackground,
      indicatorColor: palette.bubbleOutgoing,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.primary,
        side: BorderSide(color: palette.primaryLight),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.primaryLight,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.bubbleOutgoing,
      labelStyle: GoogleFonts.inter(color: palette.primaryDark),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      color: palette.divider,
      thickness: 1,
      space: 0,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? palette.selectedTile : Colors.white,
      labelStyle: GoogleFonts.inter(color: palette.textSecondary),
      hintStyle: GoogleFonts.inter(color: palette.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.accent, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.divider),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: palette.onSurface,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: palette.textSecondary,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: palette.primaryDark,
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.accent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.accent;
        }
        if (states.contains(WidgetState.disabled)) {
          return palette.textSecondary.withValues(alpha: 0.5);
        }
        return palette.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.accent.withValues(alpha: 0.45);
        }
        if (states.contains(WidgetState.disabled)) {
          return palette.divider;
        }
        return palette.textSecondary.withValues(alpha: 0.35);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.disabled)) {
          return palette.divider;
        }
        return palette.textSecondary;
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: palette.primary,
      unselectedLabelColor: palette.textSecondary,
      indicatorColor: palette.accent,
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
    ),
  );
}

/// Tema Material 3 claro para una plantilla de color.
ThemeData buildChurchTheme({required ChurchPalette palette}) =>
    _buildChurchTheme(
      brightness: Brightness.light,
      palette: palette,
    );

/// Tema Material 3 oscuro para una plantilla de color.
ThemeData buildChurchDarkTheme({required ChurchPalette palette}) =>
    _buildChurchTheme(
      brightness: Brightness.dark,
      palette: palette,
    );
