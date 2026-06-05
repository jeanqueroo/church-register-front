import 'dart:math' as math;

import '../../address/services/geocoding_service.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';

class LeaderAssignmentResult {
  const LeaderAssignmentResult({
    required this.leader,
    required this.distanceKm,
  });

  final ChurchLeader leader;
  final double distanceKm;
}

class LeaderAssignmentService {
  LeaderAssignmentService({
    LeaderService? leaderService,
    GeocodingService? geocodingService,
  })  : _leaderService = leaderService ?? LeaderService(),
        _geocodingService = geocodingService ?? GeocodingService();

  final LeaderService _leaderService;
  final GeocodingService _geocodingService;

  Future<LeaderAssignmentResult?> assignNearestLeader({
    required LeaderGender gender,
    required GeoLocation memberLocation,
    String? churchId,
  }) async {
    final leaders =
        await _leaderService.fetchAssignableLeaders(churchId: churchId);
    final candidates = <({ChurchLeader leader, double distance})>[];

    for (final leader in leaders) {
      if (leader.gender != gender) continue;

      var location = leader.geoLocation;
      if (location == null) {
        final address = leader.formattedAddress;
        if (address.isEmpty) continue;
        location = await _geocodingService.geocodeAddress(address);
        if (location == null) continue;
      }

      final distance = _distanceKm(
        memberLocation.latitude,
        memberLocation.longitude,
        location.latitude,
        location.longitude,
      );
      candidates.add((leader: leader, distance: distance));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => a.distance.compareTo(b.distance));
    final nearest = candidates.first;

    return LeaderAssignmentResult(
      leader: nearest.leader,
      distanceKm: nearest.distance,
    );
  }

  /// Distancia en km entre integrante y líder (geocodifica al líder si hace falta).
  Future<double?> distanceKmToLeader({
    required GeoLocation memberLocation,
    required ChurchLeader leader,
  }) async {
    var leaderLocation = leader.geoLocation;
    if (leaderLocation == null) {
      final address = leader.formattedAddress;
      if (address.isEmpty) return null;
      leaderLocation = await _geocodingService.geocodeAddress(address);
    }
    if (leaderLocation == null) return null;
    return distanceKmBetween(memberLocation, leaderLocation);
  }

  static double distanceKmBetween(GeoLocation a, GeoLocation b) {
    return _distanceKm(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double deg) => deg * math.pi / 180;
}
