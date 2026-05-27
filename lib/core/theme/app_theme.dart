import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Nombre visible de la aplicación.
const String appDisplayName = 'Iglesia de Dios';

/// Paleta inspirada en WhatsApp.
class AppColors {
  AppColors._();

  /// Barra superior / encabezados (teal oscuro).
  static const Color primary = Color(0xFF075E54);
  static const Color primaryDark = Color(0xFF054D45);
  static const Color primaryLight = Color(0xFF128C7E);

  /// Acento (botones, FAB, acciones).
  static const Color accent = Color(0xFF25D366);
  static const Color accentDark = Color(0xFF1DA851);

  /// Fondo tipo pantalla de chats.
  static const Color chatBackground = Color(0xFFECE5DD);
  static const Color surface = Colors.white;

  /// Textos secundarios.
  static const Color textSecondary = Color(0xFF667781);
  static const Color divider = Color(0xFFE9EDEF);

  /// Burbuja / selección suave.
  static const Color bubbleOutgoing = Color(0xFFDCF8C6);
  static const Color selectedTile = Color(0xFFF0F2F5);

  static const Color drawerBackground = surface;
}

ThemeData buildChurchTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.bubbleOutgoing,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: Color(0xFF111B21),
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.divider,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.chatBackground,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryDark,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bubbleOutgoing,
      labelStyle: const TextStyle(color: AppColors.primaryDark),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: AppColors.primaryDark,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
    ),
  );
}
