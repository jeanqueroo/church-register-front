import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/geo_location.dart';

class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({
    super.key,
    required this.location,
    this.height = 160,
  });

  final GeoLocation location;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.church.register.church_registe',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_pin,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
