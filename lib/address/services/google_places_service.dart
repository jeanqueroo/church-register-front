import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/google_maps_config.dart';
import '../../core/models/geo_location.dart';
import '../models/address_place.dart';
import '../models/parsed_address.dart';

class GooglePlacesService {
  GooglePlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://maps.googleapis.com/maps/api';

  String get _apiKey => GoogleMapsConfig.apiKey;

  void _ensureConfigured() {
    if (!GoogleMapsConfig.isConfigured) {
      throw StateError(
        'Falta la API key de Google Maps. '
        'Configura maps_api_key.dart o GOOGLE_MAPS_API_KEY.',
      );
    }
  }

  Future<List<AddressPlace>> searchPlaces(
    String query, {
    int limit = 5,
  }) async {
    _ensureConfigured();
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final uri = Uri.parse('$_baseUrl/place/autocomplete/json').replace(
      queryParameters: {
        'input': trimmed,
        'key': _apiKey,
        'language': 'es',
        'components': 'country:ar',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK' && body['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final predictions = body['predictions'] as List<dynamic>? ?? [];
    return predictions.take(limit).map((item) {
      final map = item as Map<String, dynamic>;
      return AddressPlace(
        displayName: map['description'] as String? ?? '',
        latitude: 0,
        longitude: 0,
        parsedAddress: const ParsedAddress(),
        placeId: map['place_id'] as String?,
      );
    }).where((p) => p.displayName.isNotEmpty && p.placeId != null).toList();
  }

  Future<AddressPlace?> fetchPlaceDetails(String placeId) async {
    _ensureConfigured();

    final uri = Uri.parse('$_baseUrl/place/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'key': _apiKey,
        'language': 'es',
        'fields': 'formatted_address,geometry,address_components',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK') return null;

    final result = body['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    return _placeFromDetails(result, placeId: placeId);
  }

  Future<AddressPlace> enrichPlace(AddressPlace place) async {
    if (place.placeId != null) {
      final detailed = await fetchPlaceDetails(place.placeId!);
      if (detailed != null) return detailed;
    }
    if (place.latitude != 0 || place.longitude != 0) {
      return place;
    }
    return place;
  }

  Future<GeoLocation?> geocodeAddress(String address) async {
    _ensureConfigured();
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse('$_baseUrl/geocode/json').replace(
      queryParameters: {
        'address': trimmed,
        'key': _apiKey,
        'region': 'ar',
        'language': 'es',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'OK') return null;

    final results = body['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) return null;

    return GeoLocation(
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
    );
  }

  AddressPlace _placeFromDetails(
    Map<String, dynamic> result, {
    required String placeId,
  }) {
    final formatted = result['formatted_address'] as String? ?? '';
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final components =
        result['address_components'] as List<dynamic>? ?? [];

    return AddressPlace(
      displayName: formatted,
      latitude: location != null ? (location['lat'] as num).toDouble() : 0,
      longitude: location != null ? (location['lng'] as num).toDouble() : 0,
      parsedAddress: ParsedAddress.fromGoogleAddressComponents(components),
      placeId: placeId,
    );
  }
}
