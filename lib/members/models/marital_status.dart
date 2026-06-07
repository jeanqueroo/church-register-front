import '../../l10n/app_localizations.dart';

enum MaritalStatus {
  soltero,
  casado,
  concubino,
  divorciado,
  viudo;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case MaritalStatus.soltero:
        return l10n.maritalSingle;
      case MaritalStatus.casado:
        return l10n.maritalMarried;
      case MaritalStatus.concubino:
        return l10n.maritalConcubino;
      case MaritalStatus.divorciado:
        return l10n.maritalDivorced;
      case MaritalStatus.viudo:
        return l10n.maritalWidowed;
    }
  }

  String get label {
    switch (this) {
      case MaritalStatus.soltero:
        return 'Soltero/a';
      case MaritalStatus.casado:
        return 'Casado/a';
      case MaritalStatus.concubino:
        return 'Concubino/a';
      case MaritalStatus.divorciado:
        return 'Divorciado/a';
      case MaritalStatus.viudo:
        return 'Viudo/a';
    }
  }

  static MaritalStatus? fromString(String? value) {
    if (value == null) return null;
    for (final status in MaritalStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }
}
