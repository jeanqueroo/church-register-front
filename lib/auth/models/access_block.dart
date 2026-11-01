/// Motivo por el que el usuario no puede acceder al sistema.
enum AccessBlockKind {
  user,
  church,
}

class AccessBlock {
  const AccessBlock(this.kind);

  final AccessBlockKind kind;
}
