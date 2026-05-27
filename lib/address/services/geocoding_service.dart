import '../../core/models/geo_location.dart';
import 'nominatim_service.dart';

/// Geocodificación con OpenStreetMap (Nominatim).
class GeocodingService {
  GeocodingService({NominatimService? nominatim})
      : _nominatim = nominatim ?? NominatimService();

  final NominatimService _nominatim;

  Future<GeoLocation?> geocodeAddress(String address) {
    return _nominatim.geocodeAddress(address);
  }
}
