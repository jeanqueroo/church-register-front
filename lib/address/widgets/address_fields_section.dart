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
      ],
    );
  }
}
