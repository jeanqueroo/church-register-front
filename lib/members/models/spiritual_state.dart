import '../../l10n/app_localizations.dart';

enum SpiritualState {
  nuevoCreyente,
  enDiscipulado,
  miembroActivo,
  alejado,
  visitanteFrecuente;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case SpiritualState.nuevoCreyente:
        return l10n.spiritualNewBeliever;
      case SpiritualState.enDiscipulado:
        return l10n.spiritualInDiscipleship;
      case SpiritualState.miembroActivo:
        return l10n.spiritualActiveMember;
      case SpiritualState.alejado:
        return l10n.spiritualDistant;
      case SpiritualState.visitanteFrecuente:
        return l10n.spiritualFrequentVisitor;
    }
  }

  String get label {
    switch (this) {
      case SpiritualState.nuevoCreyente:
        return 'Nuevo creyente';
      case SpiritualState.enDiscipulado:
        return 'En discipulado';
      case SpiritualState.miembroActivo:
        return 'Miembro activo';
      case SpiritualState.alejado:
        return 'Alejado';
      case SpiritualState.visitanteFrecuente:
        return 'Visitante frecuente';
    }
  }

  static SpiritualState? fromString(String? value) {
    if (value == null) return null;
    for (final state in SpiritualState.values) {
      if (state.name == value) return state;
    }
    return null;
  }
}
