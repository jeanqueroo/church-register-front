import '../../l10n/app_localizations.dart';

enum VisitPlace {
  casa,
  hospital,
  trabajo,
  iglesia,
  videollamada;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case VisitPlace.casa:
        return l10n.visitPlaceHome;
      case VisitPlace.hospital:
        return l10n.visitPlaceHospital;
      case VisitPlace.trabajo:
        return l10n.visitPlaceWork;
      case VisitPlace.iglesia:
        return l10n.visitPlaceChurch;
      case VisitPlace.videollamada:
        return l10n.visitPlaceVideoCall;
    }
  }

  String get label {
    switch (this) {
      case VisitPlace.casa:
        return 'Casa';
      case VisitPlace.hospital:
        return 'Hospital';
      case VisitPlace.trabajo:
        return 'Trabajo';
      case VisitPlace.iglesia:
        return 'Iglesia';
      case VisitPlace.videollamada:
        return 'Videollamada';
    }
  }

  static VisitPlace? fromString(String? value) {
    if (value == null) return null;
    for (final place in VisitPlace.values) {
      if (place.name == value) return place;
    }
    return null;
  }
}
