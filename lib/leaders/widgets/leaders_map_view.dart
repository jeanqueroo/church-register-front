import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/google_maps_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/external_map_launcher.dart';
import '../../core/widgets/google_maps_missing_key.dart';
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 48),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (final leader in _locatedLeaders) {
      markers.add(
        Marker(
          markerId: MarkerId('leader_${leader.id ?? leader.fullName}'),
          position: LatLng(leader.latitude!, leader.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: leader.fullName,
            snippet: leader.cellCode != null
                ? 'Célula ${leader.cellCode}'
                : 'Líder',
          ),
          onTap: () => _showLeaderSheet(leader),
        ),
      );
    }
    return markers;
  }

  Future<void> _openInGoogleMaps(ChurchLeader leader) async {
    final address = leader.formattedAddress;
    final hasCoords =
        leader.latitude != null && leader.longitude != null;
    if (!hasCoords && address.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este líder no tiene dirección para navegar.'),
        ),
      );
      return;
    }

    final opened = await ExternalMapLauncher.openGoogleMapsDirections(
      latitude: leader.latitude,
      longitude: leader.longitude,
      addressQuery: address.isNotEmpty ? address : null,
    );
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
  }

  void _showLeaderSheet(ChurchLeader leader) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final address = leader.formattedAddress;
        final canNavigate =
            leader.geoLocation != null || address.isNotEmpty;
        final parts = <String>[
          if (leader.churchOfficeLabel != null) leader.churchOfficeLabel!,
          if (leader.cellCode != null) 'Célula ${leader.cellCode}',
          leader.mobilePhone,
          if (leader.email != null && leader.email!.isNotEmpty) leader.email!,
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
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(address, style: Theme.of(ctx).textTheme.bodyMedium),
                ],
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    parts.join(' · '),
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: canNavigate
                      ? () {
                          Navigator.pop(ctx);
                          _openInGoogleMaps(leader);
                        }
                      : null,
                  icon: const Icon(Icons.directions),
                  label: const Text('Ir con Google Maps'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onLeaderTap(leader);
                  },
                  child: const Text('Ver nuevos creyentes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleMapsConfig.isConfigured) {
      return const Center(child: GoogleMapsMissingKey());
    }

    final located = _locatedLeaders;
    final withoutLocation = widget.leaders.length - located.length;
    final hasAnyPoint = _allPoints.isNotEmpty;

    if (_lastFittedLeaders != widget.leaders) {
      _lastFittedLeaders = widget.leaders;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap());
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
                '$withoutLocation ${withoutLocation == 1 ? 'líder' : 'líderes'} '
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
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Mapa: Google Maps',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
