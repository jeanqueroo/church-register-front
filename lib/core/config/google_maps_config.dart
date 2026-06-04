import 'maps_api_key.dart';

/// Configuración de Google Maps / Places / Geocoding.
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static String get apiKey {
    const fromDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (kGoogleMapsApiKey.isNotEmpty &&
        kGoogleMapsApiKey != 'TU_API_KEY_DE_GOOGLE_MAPS') {
      return kGoogleMapsApiKey;
    }
    return '';
  }

  static bool get isConfigured => apiKey.isNotEmpty;
}
