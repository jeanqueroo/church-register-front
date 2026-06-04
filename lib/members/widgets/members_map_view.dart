import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../leaders/models/church_leader.dart';
import '../models/church_member.dart';

/// Mapa de integrantes; opcionalmente muestra al líder asignado.
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
  final _mapController = MapController();
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

  void _fitMap() {
    final points = _allPoints;
    if (points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (points.length == 1) {
        _mapController.move(points.first, 14);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(48),
          ),
        );
      }
    });
  }

  void _showMemberSheet(ChurchMember member) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
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
                FilledButton(
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
    final located = _locatedMembers;
    final withoutLocation = widget.members.length - located.length;
    final leaderLoc = widget.leader?.geoLocation;
    final hasAnyPoint = _allPoints.isNotEmpty;

    if (_lastFittedMembers != widget.members) {
      _lastFittedMembers = widget.members;
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
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.church.register.church_registe',
              ),
              MarkerLayer(
                markers: [
                  if (leaderLoc != null)
                    Marker(
                      point: LatLng(leaderLoc.latitude, leaderLoc.longitude),
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.person_pin_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 48,
                      ),
                    ),
                  ...located.map(
                    (member) => Marker(
                      point: LatLng(member.latitude!, member.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showMemberSheet(member),
                        child: Icon(
                          Icons.location_pin,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
