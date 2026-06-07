import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../core/utils/external_maps.dart';
import '../../l10n/app_localizations.dart';
import '../../leaders/models/church_leader.dart';
import '../models/church_member.dart';

/// Mapa de integrantes con Google Maps; opcionalmente muestra al líder asignado.
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

  Future<void> _openDirections(BuildContext ctx, ChurchMember member) async {
    final l10n = ctx.l10n;
    final location = member.geoLocation;
    if (location == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(l10n.membersMapNoLocationSnack)),
      );
      return;
    }

    final opened = await openMapsDirections(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    if (!opened && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(l10n.membersMapNavigationFailed)),
      );
    }
  }

  List<String> _memberSheetParts(AppLocalizations l10n, ChurchMember member) {
    return [
      member.phone,
      if (member.wantsVisit) l10n.membersMapRequestsVisit,
      if (member.assignedDistanceKm != null)
        l10n.membersMapDistanceFromLeader(
          member.assignedDistanceKm!.toStringAsFixed(1),
        ),
    ];
  }

  void _showMemberSheet(ChurchMember member) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final sheetL10n = ctx.l10n;
        final address = member.formattedAddress;
        final parts = _memberSheetParts(sheetL10n, member);

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
                if (member.geoLocation != null)
                  OutlinedButton.icon(
                    onPressed: () => _openDirections(ctx, member),
                    icon: const Icon(Icons.directions_outlined),
                    label: Text(sheetL10n.membersMapGetDirections),
                  ),
                if (member.geoLocation != null) const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onMemberTap(member);
                  },
                  child: Text(sheetL10n.membersMapViewDetail),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Set<Marker> _buildMarkers(AppLocalizations l10n) {
    final markers = <Marker>{};
    final leaderLoc = widget.leader?.geoLocation;
    if (leaderLoc != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('leader'),
          position: LatLng(leaderLoc.latitude, leaderLoc.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: widget.leader!.fullName,
            snippet: l10n.membersMapLeaderLabel,
          ),
        ),
      );
    }

    for (final member in _locatedMembers) {
      final id = member.id ?? member.fullName;
      markers.add(
        Marker(
          markerId: MarkerId('member-$id'),
          position: LatLng(member.latitude!, member.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: member.fullName),
          onTap: () => _showMemberSheet(member),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final located = _locatedMembers;
    final withoutLocation = widget.members.length - located.length;
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
                l10n.membersMapEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.membersMapEmptySubtitle,
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
                l10n.membersMapMissingLocationCount(withoutLocation),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ),
        if (widget.leader?.geoLocation != null)
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
                      l10n.membersMapLeaderMarker(widget.leader!.fullName),
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
            markers: _buildMarkers(l10n),
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
