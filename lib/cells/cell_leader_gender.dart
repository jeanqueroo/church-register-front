import '../core/models/leader_gender.dart';
import '../leaders/services/leader_service.dart';
import 'models/church_cell.dart';

bool memberMatchesCellLeaderGender({
  required LeaderGender? memberGender,
  required LeaderGender? leaderGender,
}) {
  if (leaderGender == null || memberGender == null) return false;
  return memberGender == leaderGender;
}

Future<LeaderGender?> fetchCellLeaderGender(
  ChurchCell cell, {
  LeaderService? leaderService,
}) async {
  final leaderId = cell.leaderId?.trim();
  if (leaderId == null || leaderId.isEmpty) return null;
  final leader =
      await (leaderService ?? LeaderService()).fetchLeaderById(leaderId);
  return leader?.gender;
}
