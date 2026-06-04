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

  static ChurchOffice? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final office in ChurchOffice.values) {
      if (office.code == code) return office;
    }
    return null;
  }
}
