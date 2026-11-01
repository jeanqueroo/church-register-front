import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Valores guardados: [system], [es], [en].
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs);

  static const preferenceSystem = 'system';
  static const preferenceSpanish = 'es';
  static const preferenceEnglish = 'en';

  static const _prefKey = 'locale_preference';

  final SharedPreferences _prefs;
  late String _preference;

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = LocaleController(prefs);
    controller._preference = prefs.getString(_prefKey) ?? preferenceSystem;
    return controller;
  }

  String get preference => _preference;

  /// `null` = seguir idioma del sistema.
  Locale? get locale {
    if (_preference == preferenceSystem) return null;
    return Locale(_preference);
  }

  Locale resolveLocale(Locale? systemLocale) {
    if (_preference == preferenceSpanish) {
      return const Locale('es');
    }
    if (_preference == preferenceEnglish) {
      return const Locale('en');
    }
    final code = systemLocale?.languageCode;
    if (code == 'en') return const Locale('en');
    return const Locale('es');
  }

  Future<void> setPreference(String value) async {
    if (_preference == value) return;
    _preference = value;
    await _prefs.setString(_prefKey, value);
    notifyListeners();
  }
}

class AppLocaleScope extends InheritedNotifier<LocaleController> {
  const AppLocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found in widget tree');
    return scope!.notifier!;
  }
}
