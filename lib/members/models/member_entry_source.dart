import '../../l10n/app_localizations.dart';

/// Lugar o contexto por el que ingresó el creyente a la iglesia.
enum MemberEntrySource {
  campaniaFuera,
  hospital,
  evangelismo,
  iglesiaMadre;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case MemberEntrySource.campaniaFuera:
        return l10n.entrySourceCampaignOutside;
      case MemberEntrySource.hospital:
        return l10n.entrySourceHospital;
      case MemberEntrySource.evangelismo:
        return l10n.entrySourceEvangelism;
      case MemberEntrySource.iglesiaMadre:
        return l10n.entrySourceMotherChurch;
    }
  }

  String get label {
    switch (this) {
      case MemberEntrySource.campaniaFuera:
        return 'Campaña fuera de la iglesia';
      case MemberEntrySource.hospital:
        return 'Hospital';
      case MemberEntrySource.evangelismo:
        return 'Evangelismo';
      case MemberEntrySource.iglesiaMadre:
        return 'Iglesia madre';
    }
  }

  static const _legacyIglesiaHija = 'iglesiaHija';

  static MemberEntrySource? fromString(String? value) {
    if (value == null || value == _legacyIglesiaHija) return null;
    for (final source in MemberEntrySource.values) {
      if (source.name == value) return source;
    }
    return null;
  }

  /// Etiqueta para valor guardado en Firestore (incluye opciones antiguas).
  static String? storedValueLabel(String? value, AppLocalizations l10n) {
    final source = fromString(value);
    if (source != null) return source.localizedLabel(l10n);
    if (value == _legacyIglesiaHija) return l10n.entrySourceDaughterChurch;
    return null;
  }

  static String? storedValueSearchLabel(String? value) {
    final source = fromString(value);
    if (source != null) return source.label;
    if (value == _legacyIglesiaHija) return 'Iglesia hija';
    return null;
  }
}
