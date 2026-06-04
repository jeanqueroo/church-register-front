import 'package:flutter/material.dart';

import '../../core/models/geo_location.dart';
import '../../core/widgets/form_section_title.dart';
import '../services/nominatim_service.dart';
import 'address_autocomplete_field.dart';

class AddressFieldsSection extends StatefulWidget {
  const AddressFieldsSection({
    super.key,
    required this.streetController,
    required this.streetNumberController,
    required this.neighborhoodController,
    required this.localityController,
    required this.stateProvinceController,
    required this.postalCodeController,
    this.enabled = true,
    this.showSectionTitle = true,
    this.onStreetCoordinatesSelected,
    this.initialSearchText,
    this.requireAddress = true,
  });

  final TextEditingController streetController;
  final TextEditingController streetNumberController;
  final TextEditingController neighborhoodController;
  final TextEditingController localityController;
  final TextEditingController stateProvinceController;
  final TextEditingController postalCodeController;
  final bool enabled;
  final bool showSectionTitle;
  final void Function(GeoLocation location)? onStreetCoordinatesSelected;
  final String? initialSearchText;
  final bool requireAddress;

  @override
  State<AddressFieldsSection> createState() => _AddressFieldsSectionState();
}

class _AddressFieldsSectionState extends State<AddressFieldsSection> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchText != null &&
        widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _validateStreet(String? value) {
    if (!widget.requireAddress) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Busca y selecciona una dirección';
    }
    return null;
  }

  String? _validateSearch(String? value) {
    if (!widget.requireAddress) return null;
    if (widget.streetController.text.trim().isEmpty) {
      return 'Debes elegir una dirección de la lista';
    }
    return null;
  }

  void _applyPlace(NominatimPlace place) {
    final parsed = place.parsedAddress;

    _searchController.text = place.displayName;
    widget.streetController.text = place.streetLine;
    widget.streetNumberController.text = parsed.streetNumber ?? '';
    widget.neighborhoodController.text = parsed.neighborhood ?? '';
    widget.localityController.text = parsed.locality ?? '';
    if (parsed.stateProvince != null && parsed.stateProvince!.isNotEmpty) {
      widget.stateProvinceController.text = parsed.stateProvince!;
    }
    widget.postalCodeController.text = parsed.postalCode ?? '';

    widget.onStreetCoordinatesSelected?.call(place.location);
  }

  InputDecoration _lockedDecoration(
    BuildContext context, {
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      hintText: 'Se completa al buscar dirección',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSectionTitle) const FormSectionTitle('DIRECCIÓN'),
        AddressAutocompleteField(
          controller: _searchController,
          enabled: widget.enabled,
          onPlaceSelected: _applyPlace,
          labelText: widget.requireAddress
              ? 'Buscar dirección *'
              : 'Buscar dirección',
          validator: _validateSearch,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.streetController,
          readOnly: true,
          enabled: widget.enabled,
          validator: _validateStreet,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _lockedDecoration(
            context,
            labelText: widget.requireAddress ? 'Calle *' : 'Calle',
            prefixIcon: Icons.signpost_outlined,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: widget.streetNumberController,
                readOnly: true,
                enabled: widget.enabled,
                decoration: _lockedDecoration(context, labelText: 'Número'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: widget.postalCodeController,
                readOnly: true,
                enabled: widget.enabled,
                decoration: _lockedDecoration(
                  context,
                  labelText: 'Código postal',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.neighborhoodController,
          textCapitalization: TextCapitalization.words,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            labelText: 'Barrio',
            prefixIcon: Icon(Icons.location_city_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.localityController,
          readOnly: true,
          enabled: widget.enabled,
          decoration: _lockedDecoration(
            context,
            labelText: 'Localidad / Partido',
            prefixIcon: Icons.map_outlined,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.stateProvinceController,
          readOnly: true,
          enabled: widget.enabled,
          decoration: _lockedDecoration(
            context,
            labelText: 'Estado / Provincia',
            prefixIcon: Icons.public_outlined,
          ),
        ),
      ],
    );
  }
}
