import 'external_map_launcher_platform.dart'
    if (dart.library.html) 'external_map_launcher_web.dart'
    if (dart.library.io) 'external_map_launcher_io.dart';

/// Abre Google Maps (app o navegador) hacia una ubicación o dirección.
class ExternalMapLauncher {
  ExternalMapLauncher._();

  static Future<bool> openGoogleMapsDirections({
    double? latitude,
    double? longitude,
    String? addressQuery,
  }) async {
    final String? url;
    if (latitude != null && longitude != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    } else {
      final query = addressQuery?.trim();
      if (query == null || query.isEmpty) return false;
      url =
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(query)}';
    }

    return launchExternalMapUrl(url);
  }
}
