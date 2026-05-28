import 'package:flutter/material.dart';

/// Mensaje cuando falta configurar la API key de Google Maps.
class GoogleMapsMissingKey extends StatelessWidget {
  const GoogleMapsMissingKey({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    if (compact) {
      return Text(
        'Configura Google Maps (ver GOOGLE_MAPS_SETUP.md)',
        textAlign: TextAlign.center,
        style: textStyle,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Google Maps no está configurado',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Añade tu API key en lib/core/config/maps_api_key.dart '
            'y en android/local.properties (GOOGLE_MAPS_API_KEY). '
            'Consulta GOOGLE_MAPS_SETUP.md.',
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
