import 'package:url_launcher/url_launcher.dart';

/// Abre Google Maps con ruta hacia [latitude], [longitude].
Future<bool> openMapsDirections({
  required double latitude,
  required double longitude,
}) async {
  final destination = '$latitude,$longitude';
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
  );

  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
