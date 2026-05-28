import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/google_maps_config.dart';
import '../../core/models/geo_location.dart';
import '../../core/widgets/google_maps_missing_key.dart';

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
    if (!GoogleMapsConfig.isConfigured) {
      return SizedBox(
        height: height,
        child: const Center(child: GoogleMapsMissingKey(compact: true)),
      );
    }

    final point = LatLng(location.latitude, location.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: point, zoom: 15),
          markers: {
            Marker(
              markerId: const MarkerId('preview'),
              position: point,
            ),
          },
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
      ),
    );
  }
}
