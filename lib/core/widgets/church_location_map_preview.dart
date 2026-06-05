import 'package:flutter/material.dart';

import '../models/geo_location.dart';
import '../../address/widgets/location_map_preview.dart';

/// Vista previa del mapa con Google Maps.
class ChurchLocationMapPreview extends StatelessWidget {
  const ChurchLocationMapPreview({
    super.key,
    required this.location,
    this.height = 200,
  });

  final GeoLocation location;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LocationMapPreview(location: location, height: height);
  }
}
