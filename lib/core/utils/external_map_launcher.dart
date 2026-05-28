import 'package:url_launcher/url_launcher.dart';

/// Abre Google Maps (app o navegador) hacia una ubicación o dirección.
class ExternalMapLauncher {
  ExternalMapLauncher._();

  static Future<bool> openGoogleMapsDirections({
    double? latitude,
    double? longitude,
    String? addressQuery,
  }) async {
    final Uri uri;
    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
    } else {
      final query = addressQuery?.trim();
      if (query == null || query.isEmpty) return false;
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(query)}',
      );
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
