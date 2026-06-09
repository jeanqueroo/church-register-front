import '../../l10n/app_localizations.dart';

enum IdDocumentType {
  dni,
  pasaporte,
  otro;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case IdDocumentType.dni:
        return l10n.idDocumentDni;
      case IdDocumentType.pasaporte:
        return l10n.idDocumentPassport;
      case IdDocumentType.otro:
        return l10n.idDocumentOther;
    }
  }

  String get label {
    switch (this) {
      case IdDocumentType.dni:
        return 'DNI';
      case IdDocumentType.pasaporte:
        return 'Pasaporte';
      case IdDocumentType.otro:
        return 'Otro';
    }
  }

  static IdDocumentType? fromString(String? value) {
    if (value == null) return null;
    for (final type in IdDocumentType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
