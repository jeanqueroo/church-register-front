import '../../l10n/app_localizations.dart';

enum LeaderGender {
  hombre,
  mujer;

  String get code {
    switch (this) {
      case LeaderGender.hombre:
        return 'H';
      case LeaderGender.mujer:
        return 'M';
    }
  }

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case LeaderGender.hombre:
        return l10n.genderMale;
      case LeaderGender.mujer:
        return l10n.genderFemale;
    }
  }

  String get label {
    switch (this) {
      case LeaderGender.hombre:
        return 'Hombre (H)';
      case LeaderGender.mujer:
        return 'Mujer (M)';
    }
  }

  static LeaderGender? fromCode(String? value) {
    switch (value) {
      case 'H':
        return LeaderGender.hombre;
      case 'M':
        return LeaderGender.mujer;
      default:
        return null;
    }
  }
}
