import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/external_maps.dart';
import '../models/church_leader.dart';

/// Mapa de líderes con Google Maps.
class LeadersMapView extends StatefulWidget {
  const LeadersMapView({
    super.key,
    required this.leaders,
    required this.onLeaderTap,
  });

  final List<ChurchLeader> leaders;
  final ValueChanged<ChurchLeader> onLeaderTap;

  @override
  State<LeadersMapView> createState() => _LeadersMapViewState();
}

class _LeadersMapViewState extends State<LeadersMapView> {
  GoogleMapController? _mapController;
  List<ChurchLeader>? _lastFittedLeaders;

  List<ChurchLeader> get _locatedLeaders =>
      widget.leaders.where((l) => l.geoLocation != null).toList();

  List<LatLng> get _allPoints => _locatedLeaders
      .map((l) => LatLng(l.latitude!, l.longitude!))
      .toList();

  @override
  void didUpdateWidget(LeadersMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leaders != widget.leaders) {
      _fitMap();
    }
  }

  Future<void> _fitMap() async {
    final controller = _mapController;
    final points = _allPoints;
    if (controller == null || points.isEmpty) return;

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 48),
    );
  }

  Future<void> _openDirections(BuildContext ctx, ChurchLeader leader) async {
    final location = leader.geoLocation;
    if (location == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Este líder no tiene ubicación en el mapa'),
        ),
      );
      return;
    }

    final opened = await openMapsDirections(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    if (!opened && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la navegación')),
      );
    }
  }

  void _showLeaderSheet(ChurchLeader leader) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final address = leader.formattedAddress;
        final parts = <String>[
          if (leader.cellCode != null && leader.cellCode!.isNotEmpty)
            'Célula ${leader.cellCode}',
          leader.mobilePhone,
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  leader.fullName,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    parts.join(' · '),
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (leader.geoLocation != null)
                  OutlinedButton.icon(
                    onPressed: () => _openDirections(ctx, leader),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Cómo llegar'),
                  ),
                if (leader.geoLocation != null) const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onLeaderTap(leader);
                  },
                  child: const Text('Ver líder'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (var i = 0; i < _locatedLeaders.length; i++) {
      final leader = _locatedLeaders[i];
      final id = leader.id ?? leader.fullName;
      markers.add(
        Marker(
          markerId: MarkerId('leader-$id'),
          position: LatLng(leader.latitude!, leader.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: leader.fullName,
            snippet: leader.cellCode != null && leader.cellCode!.isNotEmpty
                ? 'Célula ${leader.cellCode}'
                : leader.mobilePhone,
          ),
          onTap: () => _showLeaderSheet(leader),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final located = _locatedLeaders;
    final withoutLocation = widget.leaders.length - located.length;
    final hasAnyPoint = _allPoints.isNotEmpty;

    if (_lastFittedLeaders != widget.leaders) {
      _lastFittedLeaders = widget.leaders;
      _fitMap();
    }

    if (!hasAnyPoint) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin ubicaciones en el mapa',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Los líderes necesitan dirección con coordenadas '
                'para aparecer en el mapa.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (withoutLocation > 0)
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                '$withoutLocation líder${withoutLocation == 1 ? '' : 'es'} '
                'sin ubicación en el mapa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _allPoints.first,
              zoom: 12,
            ),
            markers: _buildMarkers(),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMap();
            },
          ),
        ),
      ],
    );
  }
}
