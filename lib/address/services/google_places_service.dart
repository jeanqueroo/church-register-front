import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/maps_api_key.dart';
import '../../core/models/geo_location.dart';
import '../models/address_place.dart';
import '../models/parsed_address.dart';

/// Búsqueda de direcciones y geocodificación con Google Maps Platform.
class GooglePlacesService {
  GooglePlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _apiKey => kGoogleMapsApiKey.trim();

  bool get isConfigured =>
      _apiKey.isNotEmpty && !_apiKey.contains('YOUR_');

  Future<List<AddressPlace>> searchPlaces(
    String query, {
    int limit = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3 || !isConfigured) return [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': trimmed,
        'key': _apiKey,
        'language': 'es',
        'components': 'country:ar',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['status'] != 'OK' && map['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final predictions = (map['predictions'] as List<dynamic>? ?? [])
        .take(limit);

    return predictions.map((item) {
      final prediction = item as Map<String, dynamic>;
      final description = prediction['description'] as String? ?? '';
      return AddressPlace(
        displayName: description,
        latitude: 0,
        longitude: 0,
        parsedAddress: const ParsedAddress(),
        placeId: prediction['place_id'] as String?,
      );
    }).where((p) => p.displayName.isNotEmpty).toList();
  }

  Future<AddressPlace?> reverseGeocode(double lat, double lon) async {
    if (!isConfigured) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '$lat,$lon',
        'key': _apiKey,
        'language': 'es',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['status'] != 'OK') return null;

    final results = map['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    return _placeFromGeocodeResult(results.first as Map<String, dynamic>);
  }

  Future<AddressPlace> enrichPlace(AddressPlace place) async {
    if (place.placeId != null && place.placeId!.isNotEmpty) {
      final detailed = await _fetchPlaceDetails(place.placeId!);
      if (detailed != null) return detailed;
    }
    if (place.hasCoordinates) {
      final detailed = await reverseGeocode(place.latitude, place.longitude);
      if (detailed != null) return detailed;
    }
    return place;
  }

  Future<GeoLocation?> geocodeAddress(String address) async {
    if (!isConfigured) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': address.trim(),
        'key': _apiKey,
        'language': 'es',
        'components': 'country:AR',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['status'] != 'OK') return null;

    final results = map['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final place = _placeFromGeocodeResult(results.first as Map<String, dynamic>);
    return place.location;
  }

  Future<AddressPlace?> _fetchPlaceDetails(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': _apiKey,
        'language': 'es',
        'fields': 'formatted_address,geometry,address_components,name',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (map['status'] != 'OK') return null;

    final result = map['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    return _placeFromGeocodeResult(result, placeId: placeId);
  }

  AddressPlace _placeFromGeocodeResult(
    Map<String, dynamic> result, {
    String? placeId,
  }) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble() ?? 0;
    final lng = (location?['lng'] as num?)?.toDouble() ?? 0;
    final displayName = result['formatted_address'] as String? ??
        result['name'] as String? ??
        '';
    final components =
        result['address_components'] as List<dynamic>? ?? const [];

    return AddressPlace(
      displayName: displayName,
      latitude: lat,
      longitude: lng,
      parsedAddress: ParsedAddress.fromGoogleComponents(components),
      placeId: placeId,
    );
  }
}
