import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/google_maps_config.dart';
import '../../core/models/geo_location.dart';
import '../models/address_place.dart';
import '../services/google_places_service.dart';
import 'location_map_preview.dart';

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onPlaceSelected,
    this.onCoordinatesSelected,
    this.labelText = 'Buscar dirección',
    this.hintText = 'Escribe y elige una sugerencia...',
    this.placesService,
    this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final void Function(AddressPlace place)? onPlaceSelected;
  final void Function(GeoLocation location)? onCoordinatesSelected;
  final String labelText;
  final String hintText;
  final GooglePlacesService? placesService;
  final FormFieldValidator<String>? validator;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final _places = GooglePlacesService();
  Timer? _debounce;
  List<AddressPlace> _suggestions = [];
  bool _isSearching = false;
  bool _suppressTextListener = false;
  GeoLocation? _selectedLocation;

  GooglePlacesService get _service => widget.placesService ?? _places;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (!widget.enabled || _suppressTextListener) return;
    setState(() => _selectedLocation = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchSuggestions);
  }

  Future<void> _fetchSuggestions() async {
    if (!GoogleMapsConfig.isConfigured) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
      return;
    }

    final query = widget.controller.text;
    if (query.trim().length < 3) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _service.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar sugerencias de Google Maps.'),
        ),
      );
    }
  }

  Future<void> _selectPlace(AddressPlace place) async {
    _debounce?.cancel();
    setState(() {
      _suggestions = [];
      _isSearching = true;
    });

    final enriched = await _service.enrichPlace(place);

    if (!mounted) return;

    _suppressTextListener = true;
    widget.controller.text = enriched.displayName;
    widget.onPlaceSelected?.call(enriched);
    widget.onCoordinatesSelected?.call(enriched.location);
    _suppressTextListener = false;

    setState(() {
      _isSearching = false;
      _selectedLocation = enriched.location;
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!GoogleMapsConfig.isConfigured)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Falta la API key de Google Maps. '
                  'Configura maps_api_key.dart (ver GOOGLE_MAPS_SETUP.md).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled && GoogleMapsConfig.isConfigured,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    place.displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  dense: true,
                  onTap: widget.enabled ? () => _selectPlace(place) : null,
                );
              },
            ),
          ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 12),
          LocationMapPreview(location: _selectedLocation!),
        ],
      ],
    );
  }
}
