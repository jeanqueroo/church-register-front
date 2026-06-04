import 'package:flutter/material.dart';

import '../config/maps_api_key.dart';
import '../models/geo_location.dart';
import '../../address/widgets/location_map_preview.dart';

/// Vista previa del mapa: Google Static Maps si hay API key; si no, OpenStreetMap.
class ChurchLocationMapPreview extends StatelessWidget {
  const ChurchLocationMapPreview({
    super.key,
    required this.location,
    this.height = 200,
  });

  final GeoLocation location;
  final double height;

  bool get _useGoogleMaps =>
      kGoogleMapsApiKey.trim().isNotEmpty &&
      !kGoogleMapsApiKey.contains('YOUR_');

  String _googleStaticMapUrl() {
    final lat = location.latitude;
    final lng = location.longitude;
    final key = Uri.encodeComponent(kGoogleMapsApiKey.trim());
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng&zoom=16&size=640x320&scale=2'
        '&markers=color:0x075E54%7C$lat,$lng&key=$key';
  }

  @override
  Widget build(BuildContext context) {
    if (!_useGoogleMaps) {
      return LocationMapPreview(location: location, height: height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _googleStaticMapUrl(),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => LocationMapPreview(
                location: location,
                height: height,
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Google Maps',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
