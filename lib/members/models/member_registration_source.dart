import '../../l10n/app_localizations.dart';

/// Pantalla o flujo con el que se creó el documento del creyente.
enum MemberRegistrationSource {
  registerMember,
  registerMemberCell,
  registerCellMember,
  registerBaptismBeliever;

  String get storageKey => name;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case MemberRegistrationSource.registerMember:
        return l10n.memberRegistrationSourceRegisterMember;
      case MemberRegistrationSource.registerMemberCell:
        return l10n.memberRegistrationSourceRegisterMemberCell;
      case MemberRegistrationSource.registerCellMember:
        return l10n.memberRegistrationSourceRegisterCellMember;
      case MemberRegistrationSource.registerBaptismBeliever:
        return l10n.memberRegistrationSourceRegisterBaptismBeliever;
    }
  }

  static MemberRegistrationSource? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    for (final source in MemberRegistrationSource.values) {
      if (source.name == value || source.storageKey == value) {
        return source;
      }
    }
    return null;
  }
}
