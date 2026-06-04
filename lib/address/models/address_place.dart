import '../../core/models/geo_location.dart';
import 'parsed_address.dart';

/// Dirección seleccionada desde autocompletado o geocodificación.
class AddressPlace {
  const AddressPlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.parsedAddress,
    this.placeId,
  });

  final String displayName;
  final double latitude;
  final double longitude;
  final ParsedAddress parsedAddress;
  final String? placeId;

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
