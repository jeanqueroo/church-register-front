import 'church_member.dart';

/// Filtro de la lista de integrantes (alineado con el resumen del home).
enum MembersListFilter {
  /// Solo nuevos creyentes (`isNewBeliever == true`), sin liderazgo promovido.
  newBelievers,

  /// Miembros activos de la iglesia: sin nuevos creyentes ni liderazgo promovido.
  activeChurchMembers,
}

extension MembersListFilterX on MembersListFilter {
  bool matches(ChurchMember member) {
    if (member.hasPromotedLeadershipStatus) return false;
    return switch (this) {
      MembersListFilter.newBelievers => member.isNewBeliever,
      MembersListFilter.activeChurchMembers => !member.isNewBeliever,
    };
  }

  /// Restringe la consulta Firestore cuando es posible.
  bool? get firestoreIsNewBelieverEquals => switch (this) {
        MembersListFilter.newBelievers => true,
        MembersListFilter.activeChurchMembers => false,
      };
}
