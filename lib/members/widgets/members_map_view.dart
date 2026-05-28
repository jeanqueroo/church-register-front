import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/google_maps_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/external_map_launcher.dart';
import '../../core/widgets/google_maps_missing_key.dart';
import '../../leaders/models/church_leader.dart';
import '../models/church_member.dart';

/// Mapa de integrantes con Google Maps; opcionalmente muestra al líder.
class MembersMapView extends StatefulWidget {
  const MembersMapView({
    super.key,
    required this.members,
    required this.onMemberTap,
    this.leader,
  });

  final List<ChurchMember> members;
  final ValueChanged<ChurchMember> onMemberTap;
  final ChurchLeader? leader;

  @override
  State<MembersMapView> createState() => _MembersMapViewState();
}

class _MembersMapViewState extends State<MembersMapView> {
  GoogleMapController? _mapController;
  List<ChurchMember>? _lastFittedMembers;

  List<ChurchMember> get _locatedMembers =>
      widget.members.where((m) => m.geoLocation != null).toList();

  List<LatLng> get _allPoints {
    final points = <LatLng>[];
    final leaderLoc = widget.leader?.geoLocation;
    if (leaderLoc != null) {
      points.add(LatLng(leaderLoc.latitude, leaderLoc.longitude));
    }
    for (final m in _locatedMembers) {
      points.add(LatLng(m.latitude!, m.longitude!));
    }
    return points;
  }

  @override
  void didUpdateWidget(MembersMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members ||
        oldWidget.leader != widget.leader) {
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
    final leaderLoc = widget.leader?.geoLocation;
    if (leaderLoc != null) {
      markers.add(
        Marker(
          markerId: MarkerId('leader_${widget.leader!.id ?? 'x'}'),
          position: LatLng(leaderLoc.latitude, leaderLoc.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: widget.leader!.fullName,
            snippet: 'Líder',
          ),
        ),
      );
    }

    for (final member in _locatedMembers) {
      markers.add(
        Marker(
          markerId: MarkerId('member_${member.id ?? member.fullName}'),
          position: LatLng(member.latitude!, member.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: member.fullName),
          onTap: () => _showMemberSheet(member),
        ),
      );
    }

    return markers;
  }

  Future<void> _openInGoogleMaps(ChurchMember member) async {
    final address = member.formattedAddress;
    final hasCoords =
        member.latitude != null && member.longitude != null;
    if (!hasCoords && address.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este integrante no tiene dirección para navegar.'),
        ),
      );
      return;
    }

    final opened = await ExternalMapLauncher.openGoogleMapsDirections(
      latitude: member.latitude,
      longitude: member.longitude,
      addressQuery: address.isNotEmpty ? address : null,
    );
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Maps.'),
        ),
      );
    }
  }

  void _showMemberSheet(ChurchMember member) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final address = member.formattedAddress;
        final canNavigate =
            member.geoLocation != null || address.isNotEmpty;
        final parts = <String>[
          member.phone,
          if (member.wantsVisit) 'Solicita visita',
          if (member.locality != null) member.locality!,
          if (member.assignedDistanceKm != null)
            '${member.assignedDistanceKm!.toStringAsFixed(1)} km del líder',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  member.fullName,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 20,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
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
                          _openInGoogleMaps(member);
                        }
                      : null,
                  icon: const Icon(Icons.directions),
                  label: const Text('Ir con Google Maps'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onMemberTap(member);
                  },
                  child: const Text('Ver detalle'),
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

    final located = _locatedMembers;
    final withoutLocation = widget.members.length - located.length;
    final leaderLoc = widget.leader?.geoLocation;
    final hasAnyPoint = _allPoints.isNotEmpty;

    if (_lastFittedMembers != widget.members) {
      _lastFittedMembers = widget.members;
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
                'Los integrantes necesitan dirección con coordenadas '
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

    final initialCenter = _allPoints.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (withoutLocation > 0)
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                '$withoutLocation integrante${withoutLocation == 1 ? '' : 's'} '
                'sin ubicación en el mapa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ),
        if (leaderLoc != null)
          Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.supervisor_account,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Marcador morado: ${widget.leader!.fullName} (líder)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialCenter,
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
