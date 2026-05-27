import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/models/geo_location.dart';
import '../models/parsed_address.dart';

class NominatimPlace {
  const NominatimPlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.parsedAddress,
  });

  final String displayName;
  final double latitude;
  final double longitude;
  final ParsedAddress parsedAddress;

  GeoLocation get location =>
      GeoLocation(latitude: latitude, longitude: longitude);

  String get streetLine {
    final street = parsedAddress.street;
    if (street != null && street.isNotEmpty) {
      return street;
    }
    final parts = displayName.split(',');
    if (parts.isEmpty) return displayName;
    return ParsedAddress.splitStreetAndNumber(parts.first.trim()).street;
  }
}

class NominatimService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _userAgent = 'church-register-app/1.0 (Iglesia de Dios)';

  Future<List<NominatimPlace>> searchPlaces(
    String query, {
    int limit = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': trimmed,
        'format': 'json',
        'limit': '$limit',
        'addressdetails': '1',
        'countrycodes': 'ar',
      },
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map(_placeFromSearchJson).where((p) => p.displayName.isNotEmpty).toList();
  }

  /// Geocodificación inversa: suele devolver `house_number` más preciso.
  Future<NominatimPlace?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(
      queryParameters: {
        'lat': '$lat',
        'lon': '$lon',
        'format': 'json',
        'addressdetails': '1',
      },
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) return null;

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['error'] != null) return null;

    return _placeFromSearchJson(map);
  }

  /// Refina la dirección con reverse geocoding al seleccionar.
  Future<NominatimPlace> enrichPlace(NominatimPlace place) async {
    final detailed = await reverseGeocode(place.latitude, place.longitude);
    if (detailed == null) return place;

    final merged = ParsedAddress(
      street: detailed.parsedAddress.street ?? place.parsedAddress.street,
      streetNumber: detailed.parsedAddress.streetNumber ??
          place.parsedAddress.streetNumber,
      neighborhood: detailed.parsedAddress.neighborhood ??
          place.parsedAddress.neighborhood,
      locality:
          detailed.parsedAddress.locality ?? place.parsedAddress.locality,
      stateProvince: detailed.parsedAddress.stateProvince ??
          place.parsedAddress.stateProvince,
      postalCode:
          detailed.parsedAddress.postalCode ?? place.parsedAddress.postalCode,
    );

    return NominatimPlace(
      displayName: detailed.displayName.isNotEmpty
          ? detailed.displayName
          : place.displayName,
      latitude: place.latitude,
      longitude: place.longitude,
      parsedAddress: merged,
    );
  }

  Future<GeoLocation?> geocodeAddress(String address) async {
    final results = await searchPlaces(address, limit: 1);
    if (results.isEmpty) return null;
    return results.first.location;
  }

  NominatimPlace _placeFromSearchJson(dynamic item) {
    final map = item as Map<String, dynamic>;
    final addressMap = map['address'] as Map<String, dynamic>?;
    final displayName = map['display_name'] as String? ?? '';

    return NominatimPlace(
      displayName: displayName,
      latitude: double.parse(map['lat'].toString()),
      longitude: double.parse(map['lon'].toString()),
      parsedAddress: ParsedAddress.fromNominatim(
        addressMap,
        displayName: displayName,
      ),
    );
  }
}
