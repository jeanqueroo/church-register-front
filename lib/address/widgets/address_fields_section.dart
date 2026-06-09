import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../core/models/geo_location.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../models/address_place.dart';
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
    this.onAddressCleared,
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
  final VoidCallback? onAddressCleared;
  final String? initialSearchText;
  final bool requireAddress;

  @override
  State<AddressFieldsSection> createState() => _AddressFieldsSectionState();
}

class _AddressFieldsSectionState extends State<AddressFieldsSection> {
  final _searchController = TextEditingController();
  bool _suggestionsLocked = false;

  bool get _hasAddressData => widget.streetController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchText != null &&
        widget.initialSearchText!.isNotEmpty) {
      _searchController.text = widget.initialSearchText!;
    }
    if (widget.streetController.text.trim().isNotEmpty) {
      _suggestionsLocked = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _validateStreet(String? value, AppLocalizations l10n) {
    if (!widget.requireAddress) return null;
    if (value == null || value.trim().isEmpty) {
      return l10n.addressSearchAndSelect;
    }
    return null;
  }

  String? _validateSearch(String? value, AppLocalizations l10n) {
    if (!widget.requireAddress) return null;
    if (widget.streetController.text.trim().isEmpty) {
      return l10n.addressMustPickFromList;
    }
    return null;
  }

  void _clearAddressFields() {
    widget.streetController.clear();
    widget.streetNumberController.clear();
    widget.neighborhoodController.clear();
    widget.localityController.clear();
    widget.postalCodeController.clear();
    widget.onAddressCleared?.call();
  }

  void _unlockAddressSearch({bool clearFields = false}) {
    setState(() => _suggestionsLocked = false);
    if (clearFields) {
      _searchController.clear();
      _clearAddressFields();
    }
  }

  void _applyPlace(AddressPlace place) {
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

    setState(() => _suggestionsLocked = true);
    widget.onStreetCoordinatesSelected?.call(place.location);
  }

  InputDecoration _lockedDecoration(
    BuildContext context, {
    required String labelText,
    required AppLocalizations l10n,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      hintText: l10n.addressAutoFilledHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSectionTitle) FormSectionTitle(l10n.addressSection),
        AddressAutocompleteField(
          controller: _searchController,
          enabled: widget.enabled,
          onPlaceSelected: _applyPlace,
          suggestionsLocked: _suggestionsLocked,
          onTapWhenLocked: () => _unlockAddressSearch(),
          labelText: widget.requireAddress
              ? l10n.addressSearchRequired
              : l10n.addressSearchOptional,
          hintText: _suggestionsLocked && _hasAddressData
              ? l10n.addressSearchTapToChange
              : l10n.addressSearchHint,
          validator: (value) => _validateSearch(value, l10n),
        ),
        if (_suggestionsLocked && _hasAddressData && widget.enabled) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _unlockAddressSearch(clearFields: true),
              icon: const Icon(Icons.edit_location_alt_outlined, size: 20),
              label: Text(l10n.addressChangeButton),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.streetController,
          readOnly: true,
          enabled: widget.enabled,
          validator: (value) => _validateStreet(value, l10n),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _lockedDecoration(
            context,
            labelText: widget.requireAddress
                ? l10n.addressStreetRequired
                : l10n.addressStreetOptional,
            l10n: l10n,
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
                decoration: _lockedDecoration(
                  context,
                  labelText: l10n.addressNumber,
                  l10n: l10n,
                ),
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
                  labelText: l10n.addressPostalCode,
                  l10n: l10n,
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
          decoration: InputDecoration(
            labelText: l10n.addressNeighborhood,
            prefixIcon: const Icon(Icons.location_city_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.localityController,
          readOnly: true,
          enabled: widget.enabled,
          decoration: _lockedDecoration(
            context,
            labelText: l10n.addressLocality,
            l10n: l10n,
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
            labelText: l10n.addressStateProvince,
            l10n: l10n,
            prefixIcon: Icons.public_outlined,
          ),
        ),
      ],
    );
  }
}
