import '../../core/models/geo_location.dart';
import 'google_places_service.dart';

/// Geocodificación con Google Geocoding API.
class GeocodingService {
  GeocodingService({GooglePlacesService? places})
      : _places = places ?? GooglePlacesService();

  final GooglePlacesService _places;

  Future<GeoLocation?> geocodeAddress(String address) {
    return _places.geocodeAddress(address);
  }
}
