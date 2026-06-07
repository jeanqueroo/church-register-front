import '../../l10n/app_localizations.dart';

/// Cargo en la iglesia (campo `churchOffice` en Firestore / `leaders`).
enum ChurchOffice {
  lideres('lideres', 'Líderes'),
  ancianoMenor('anciano_menor', 'Anciano menor'),
  anciano('anciano', 'Anciano'),
  ancianoMayor('anciano_mayor', 'Anciano mayor'),
  voluntario('voluntario', 'Voluntario');

  const ChurchOffice(this.code, this.label);

  final String code;
  final String label;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ChurchOffice.lideres:
        return l10n.churchOfficeLeader;
      case ChurchOffice.ancianoMenor:
        return l10n.churchOfficeJuniorElder;
      case ChurchOffice.anciano:
        return l10n.churchOfficeElder;
      case ChurchOffice.ancianoMayor:
        return l10n.churchOfficeSeniorElder;
      case ChurchOffice.voluntario:
        return l10n.churchOfficeVolunteer;
    }
  }

  static ChurchOffice? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final office in ChurchOffice.values) {
      if (office.code == code) return office;
    }
    return null;
  }
}
