import '../../l10n/app_localizations.dart';

class PasswordValidator {
  static final RegExp _hasLetter = RegExp(r'[A-Za-zÀ-ÿ]');
  static final RegExp _hasNumber = RegExp(r'\d');
  static final RegExp _hasSpecial = RegExp(r'[^A-Za-zÀ-ÿ0-9]');

  /// Valida contraseñas al registrar o al definir una nueva clave.
  static String? validateRegistration(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 8) return l10n.passwordRegistrationMinLength;
    if (!_hasLetter.hasMatch(value)) {
      return l10n.passwordRegistrationNeedsLetter;
    }
    if (!_hasNumber.hasMatch(value)) {
      return l10n.passwordRegistrationNeedsNumber;
    }
    if (!_hasSpecial.hasMatch(value)) {
      return l10n.passwordRegistrationNeedsSpecial;
    }
    return null;
  }
}
