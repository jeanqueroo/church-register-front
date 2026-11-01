import '../../l10n/app_localizations.dart';

/// Pantalla o flujo con el que se creó el documento del líder.
enum LeaderRegistrationSource {
  registerLeader,
  registerCell;

  String get storageKey => name;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case LeaderRegistrationSource.registerLeader:
        return l10n.leaderRegistrationSourceRegisterLeader;
      case LeaderRegistrationSource.registerCell:
        return l10n.leaderRegistrationSourceRegisterCell;
    }
  }

  static LeaderRegistrationSource? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    for (final source in LeaderRegistrationSource.values) {
      if (source.name == value || source.storageKey == value) {
        return source;
      }
    }
    return null;
  }
}
