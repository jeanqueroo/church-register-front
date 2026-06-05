enum SpiritualState {
  nuevoCreyente,
  enDiscipulado,
  miembroActivo,
  alejado,
  visitanteFrecuente;

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
