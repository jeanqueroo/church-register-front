import '../../l10n/app_localizations.dart';

enum MemberLeadershipStatus {
  promotedToLeader,
  promotedToVolunteer,
  createdAsLeader;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case MemberLeadershipStatus.promotedToLeader:
        return l10n.memberLeadershipPromotedToLeader;
      case MemberLeadershipStatus.promotedToVolunteer:
        return l10n.memberLeadershipPromotedToVolunteer;
      case MemberLeadershipStatus.createdAsLeader:
        return l10n.memberLeadershipCreatedAsLeader;
    }
  }

  static MemberLeadershipStatus? fromString(String? value) {
    if (value == null) return null;
    for (final status in MemberLeadershipStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }
}
