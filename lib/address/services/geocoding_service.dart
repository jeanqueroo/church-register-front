import '../../core/models/geo_location.dart';
import 'google_places_service.dart';

/// Geocodificación con Google Maps Platform.
class GeocodingService {
  GeocodingService({GooglePlacesService? placesService})
      : _placesService = placesService ?? GooglePlacesService();

  final GooglePlacesService _placesService;

  Future<GeoLocation?> geocodeAddress(String address) {
    return _placesService.geocodeAddress(address);
  }
}
