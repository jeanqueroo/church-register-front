import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'church_palette.dart';
import 'theme_templates.dart';

/// Valores de modo: [system], [light], [dark].
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs);

  static const preferenceSystem = 'system';
  static const preferenceLight = 'light';
  static const preferenceDark = 'dark';

  static const _modePrefKey = 'theme_preference';
  static const _templatePrefKey = 'color_template_preference';

  final SharedPreferences _prefs;
  late String _preference;
  late String _templateId;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController(prefs);
    controller._preference = prefs.getString(_modePrefKey) ?? preferenceSystem;
    controller._templateId =
        prefs.getString(_templatePrefKey) ?? defaultTemplateId;
    return controller;
  }

  String get preference => _preference;

  String get templateId => _templateId;

  ThemeTemplate get template => themeTemplateById(_templateId);

  ChurchPalette get lightPalette => template.light;

  ChurchPalette get darkPalette => template.dark;

  ThemeMode get themeMode {
    switch (_preference) {
      case preferenceLight:
        return ThemeMode.light;
      case preferenceDark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setPreference(String value) async {
    if (_preference == value) return;
    _preference = value;
    await _prefs.setString(_modePrefKey, value);
    notifyListeners();
  }

  Future<void> setTemplateId(String id) async {
    if (_templateId == id) return;
    _templateId = id;
    await _prefs.setString(_templatePrefKey, id);
    notifyListeners();
  }
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
