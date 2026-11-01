import 'package:flutter/material.dart';

import 'church_palette.dart';
import 'theme_templates.dart';

/// Tema fijo: plantilla Manantial y modo claro.
class ThemeController extends ChangeNotifier {
  ThemeController();

  static Future<ThemeController> load() async => ThemeController();

  String get templateId => ThemeTemplateIds.manantial;

  ThemeTemplate get template => manantialTemplate;

  ChurchPalette get lightPalette => template.light;

  ChurchPalette get darkPalette => template.dark;

  ThemeMode get themeMode => ThemeMode.light;
}

class AppThemeScope extends InheritedNotifier<ThemeController> {
  const AppThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope not found in widget tree');
    return scope!.notifier!;
  }
}
