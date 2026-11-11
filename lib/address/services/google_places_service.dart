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

  /// Autocomplete (New): `places.googleapis.com/v1/places:autocomplete`
  Future<List<AddressPlace>> searchPlaces(
    String query, {
    int limit = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3 || !isConfigured) return [];

    final uri = Uri.https(
      'places.googleapis.com',
      '/v1/places:autocomplete',
    );

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
      },
      body: jsonEncode({
        'input': trimmed,
        'languageCode': 'es',
        'includedRegionCodes': ['ar'],
      }),
    );

    if (response.statusCode != 200) {
      throw GooglePlacesException(
        'autocomplete_http_${response.statusCode}',
        _errorMessageFromBody(response.body),
      );
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = (map['suggestions'] as List<dynamic>? ?? []).take(limit);

    final places = <AddressPlace>[];
    for (final item in suggestions) {
      final suggestion = item as Map<String, dynamic>;
      final prediction =
          suggestion['placePrediction'] as Map<String, dynamic>?;
      if (prediction == null) continue;

      final description = _predictionText(prediction);
      if (description.isEmpty) continue;

      final placeId = _normalizePlaceId(
        prediction['placeId'] as String? ?? prediction['place'] as String?,
      );

      places.add(
        AddressPlace(
          displayName: description,
          latitude: 0,
          longitude: 0,
          parsedAddress: const ParsedAddress(),
          placeId: placeId,
        ),
      );
    }
    return places;
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

    return _placeFromLegacyGeocodeResult(results.first as Map<String, dynamic>);
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

    final place =
        _placeFromLegacyGeocodeResult(results.first as Map<String, dynamic>);
    return place.location;
  }

  Future<AddressPlace?> _fetchPlaceDetails(String placeId) async {
    final id = _normalizePlaceId(placeId);
    if (id == null || id.isEmpty) return null;

    final uri = Uri.parse(
      'https://places.googleapis.com/v1/places/${Uri.encodeComponent(id)}',
    );

    final response = await _client.get(
      uri,
      headers: {
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask':
            'id,formattedAddress,location,addressComponents,displayName',
        'X-Goog-LanguageCode': 'es',
      },
    );

    if (response.statusCode != 200) return null;

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return _placeFromNewDetails(result, placeId: id);
  }

  AddressPlace _placeFromNewDetails(
    Map<String, dynamic> result, {
    String? placeId,
  }) {
    final location = result['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (location?['longitude'] as num?)?.toDouble() ?? 0;
    final displayName = (result['formattedAddress'] as String?)?.trim() ??
        ((result['displayName'] as Map<String, dynamic>?)?['text'] as String?)
            ?.trim() ??
        '';
    final components =
        result['addressComponents'] as List<dynamic>? ?? const [];

    return AddressPlace(
      displayName: displayName,
      latitude: lat,
      longitude: lng,
      parsedAddress: ParsedAddress.fromGoogleComponents(components),
      placeId: placeId,
    );
  }

  AddressPlace _placeFromLegacyGeocodeResult(
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
      placeId: placeId ?? result['place_id'] as String?,
    );
  }

  static String _predictionText(Map<String, dynamic> prediction) {
    final textObj = prediction['text'] as Map<String, dynamic>?;
    final direct = (textObj?['text'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final structured = prediction['structuredFormat'] as Map<String, dynamic>?;
    final mainText = structured?['mainText'] as Map<String, dynamic>?;
    final main = (mainText?['text'] as String?)?.trim();
    return main ?? '';
  }

  static String? _normalizePlaceId(String? raw) {
    if (raw == null) return null;
    var id = raw.trim();
    if (id.isEmpty) return null;
    const prefix = 'places/';
    if (id.startsWith(prefix)) {
      id = id.substring(prefix.length);
    }
    return id;
  }

  static String? _errorMessageFromBody(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final error = map['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      if (message != null && message.trim().isNotEmpty) return message.trim();
      final status = map['status'] as String?;
      return status;
    } catch (_) {
      return null;
    }
  }
}

class GooglePlacesException implements Exception {
  GooglePlacesException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() =>
      message == null || message!.isEmpty ? code : '$code: $message';
}
