import 'dart:async';

import 'package:flutter/material.dart';

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
    this.showInlineMapPreview = true,
    this.suggestionsLocked = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final void Function(AddressPlace place)? onPlaceSelected;
  final void Function(GeoLocation location)? onCoordinatesSelected;
  final String labelText;
  final String hintText;
  final GooglePlacesService? placesService;
  final FormFieldValidator<String>? validator;
  final bool showInlineMapPreview;
  final bool suggestionsLocked;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final _placesService = GooglePlacesService();
  Timer? _debounce;
  List<AddressPlace> _suggestions = [];
  bool _isSearching = false;
  GeoLocation? _selectedLocation;
  bool _ignoreTextChangeAfterSelect = false;

  GooglePlacesService get _service => widget.placesService ?? _placesService;

  @override
  void didUpdateWidget(AddressAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestionsLocked && !oldWidget.suggestionsLocked) {
      _debounce?.cancel();
      if (_suggestions.isNotEmpty || _isSearching) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    }
  }

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
    if (!widget.enabled) return;

    if (_ignoreTextChangeAfterSelect) {
      _ignoreTextChangeAfterSelect = false;
      return;
    }

    if (widget.suggestionsLocked) return;

    setState(() => _selectedLocation = null);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchSuggestions);
  }

  Future<void> _fetchSuggestions() async {
    if (widget.suggestionsLocked) return;

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

    if (!_service.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Configura la API key de Google Maps en maps_api_key.dart',
            ),
          ),
        );
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
    _ignoreTextChangeAfterSelect = true;
    setState(() {
      _suggestions = [];
      _isSearching = true;
    });

    final enriched = await _service.enrichPlace(place);

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _selectedLocation = enriched.location;
      _suggestions = [];
    });
    widget.onPlaceSelected?.call(enriched);
    widget.onCoordinatesSelected?.call(enriched.location);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
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
        if (!widget.suggestionsLocked && _suggestions.isNotEmpty)
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
        if (widget.showInlineMapPreview && _selectedLocation != null) ...[
          const SizedBox(height: 12),
          LocationMapPreview(location: _selectedLocation!),
        ],
      ],
    );
  }
}
