import '../../l10n/app_localizations.dart';

/// Origen de la asignación al líder / célula.
enum MemberAssignmentKind {
  /// Nuevo creyente registrado y asignado a un líder pastoral para visita.
  pastoral,

  /// Integrante o discípulo asignado a una célula.
  cell;

  String get storageKey => name;

  String label(AppLocalizations l10n) {
    switch (this) {
      case MemberAssignmentKind.pastoral:
        return l10n.memberAssignmentPastoral;
      case MemberAssignmentKind.cell:
        return l10n.memberAssignmentCell;
    }
  }

  static MemberAssignmentKind? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    for (final kind in MemberAssignmentKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }
}
