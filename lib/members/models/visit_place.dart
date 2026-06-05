enum VisitPlace {
  casa,
  hospital,
  trabajo,
  iglesia,
  videollamada;

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
