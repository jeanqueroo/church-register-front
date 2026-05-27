enum MaritalStatus {
  soltero,
  casado,
  concubino,
  divorciado,
  viudo;

  String get label {
    switch (this) {
      case MaritalStatus.soltero:
        return 'Soltero/a';
      case MaritalStatus.casado:
        return 'Casado/a';
      case MaritalStatus.concubino:
        return 'Concubino/a';
      case MaritalStatus.divorciado:
        return 'Divorciado/a';
      case MaritalStatus.viudo:
        return 'Viudo/a';
    }
  }

  static MaritalStatus? fromString(String? value) {
    if (value == null) return null;
    for (final status in MaritalStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }
}
