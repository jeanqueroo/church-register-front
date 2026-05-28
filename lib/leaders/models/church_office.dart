/// Cargo en la iglesia (campo `churchOffice` en Firestore).
enum ChurchOffice {
  lideres('lideres', 'Líderes'),
  ancianoMenor('anciano_menor', 'Anciano menor'),
  anciano('anciano', 'Anciano'),
  ancianoMayor('anciano_mayor', 'Anciano mayor');

  const ChurchOffice(this.code, this.label);

  final String code;
  final String label;

  static ChurchOffice? fromCode(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final office in ChurchOffice.values) {
      if (office.code == value) return office;
    }
    return null;
  }
}
