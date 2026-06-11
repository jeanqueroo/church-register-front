import '../../l10n/app_localizations.dart';

/// Lugar o contexto por el que ingresó el creyente a la iglesia.
enum MemberEntrySource {
  campaniaFuera,
  hospital,
  evangelismo,
  iglesiaMadre,
  iglesiaHija;

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
      case MemberEntrySource.iglesiaHija:
        return l10n.entrySourceDaughterChurch;
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
      case MemberEntrySource.iglesiaHija:
        return 'Iglesia hija';
    }
  }

  static MemberEntrySource? fromString(String? value) {
    if (value == null) return null;
    for (final source in MemberEntrySource.values) {
      if (source.name == value) return source;
    }
    return null;
  }
}
