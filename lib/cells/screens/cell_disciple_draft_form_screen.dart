import 'package:flutter/material.dart';

import '../../address/services/geocoding_service.dart';
import '../../address/widgets/address_fields_section.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/id_document_type.dart';
import '../models/cell_disciple_draft.dart';

/// Formulario de discípulo que devuelve un [CellDiscipleDraft] al guardar.
class CellDiscipleDraftFormScreen extends StatefulWidget {
  const CellDiscipleDraftFormScreen({
    super.key,
    this.title,
    this.cellCode,
    this.initial,
    this.header,
    this.persistDraft,
  });

  final String? title;
  final String? cellCode;
  final CellDiscipleDraft? initial;
  final Widget? header;
  final Future<void> Function(CellDiscipleDraft draft)? persistDraft;

  @override
  State<CellDiscipleDraftFormScreen> createState() =>
      _CellDiscipleDraftFormScreenState();
}

class _CellDiscipleDraftFormScreenState
    extends State<CellDiscipleDraftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _cellCodeController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _localityController = TextEditingController();
  final _stateProvinceController = TextEditingController(text: 'Buenos Aires');
  final _postalCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobilePhoneController = TextEditingController();
  final _idDocumentNumberController = TextEditingController();

  final _geocodingService = GeocodingService();

  LeaderGender? _gender;
  IdDocumentType? _idDocumentType;
  DateTime? _birthDate;
  GeoLocation? _location;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _lastNameController.text = initial.lastName;
      _firstNameController.text = initial.firstName;
      _streetController.text = initial.street ?? '';
      _streetNumberController.text = initial.streetNumber ?? '';
      _neighborhoodController.text = initial.neighborhood ?? '';
      _localityController.text = initial.locality ?? '';
      _stateProvinceController.text = initial.stateProvince ?? 'Buenos Aires';
      _postalCodeController.text = initial.postalCode ?? '';
      _emailController.text = initial.email ?? '';
      _mobilePhoneController.text = initial.mobilePhone;
      _idDocumentNumberController.text = initial.idDocumentNumber ?? '';
      _gender = initial.gender;
      _idDocumentType = initial.idDocumentType;
      _birthDate = initial.birthDate;
      _location = GeoLocation(
        latitude: initial.latitude,
        longitude: initial.longitude,
      );
    }
    final code = widget.cellCode?.trim();
    if (code != null && code.isNotEmpty) {
      _cellCodeController.text = code;
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _cellCodeController.dispose();
    _neighborhoodController.dispose();
    _localityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _emailController.dispose();
    _mobilePhoneController.dispose();
    _idDocumentNumberController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  int? _ageFromBirthDate(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    var years = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      years--;
    }
    return years;
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required String clearDateLabel,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _isSaving ? null : onTap,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: const OutlineInputBorder(),
              filled: true,
            ),
            child: Text(value),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSaving ? null : onClear,
              child: Text(clearDateLabel),
            ),
          ),
        ],
      ],
    );
  }

  Widget _idDocumentTypeSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.memberIdDocumentType,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: IdDocumentType.values.map((type) {
            return FilterChip(
              label: Text(type.localizedLabel(l10n)),
              selected: _idDocumentType == type,
              onSelected: _isSaving
                  ? null
                  : (v) => setState(() => _idDocumentType = v ? type : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _buildFormattedAddress() {
    return [
      _streetController.text.trim(),
      _streetNumberController.text.trim(),
      _neighborhoodController.text.trim(),
      _localityController.text.trim(),
      _stateProvinceController.text.trim(),
      _postalCodeController.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;

    setState(() => _isSaving = true);
    try {
      var location = _location;
      if (location == null) {
        final address = _buildFormattedAddress();
        if (address.isNotEmpty) {
          location = await _geocodingService.geocodeAddress(address);
        }
      }
      if (location == null) {
        if (mounted) _showMessage(l10n.memberAddressGeocodeFailed);
        return;
      }

      final email = _emailController.text.trim();
      final draft = CellDiscipleDraft(
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        street: _streetController.text.trim().isEmpty
            ? null
            : _streetController.text.trim(),
        streetNumber: _streetNumberController.text.trim().isEmpty
            ? null
            : _streetNumberController.text.trim(),
        gender: _gender,
        idDocumentType: _idDocumentType,
        idDocumentNumber: _idDocumentNumberController.text.trim().isEmpty
            ? null
            : _idDocumentNumberController.text.trim(),
        birthDate: _birthDate,
        neighborhood: _neighborhoodController.text.trim().isEmpty
            ? null
            : _neighborhoodController.text.trim(),
        locality: _localityController.text.trim().isEmpty
            ? null
            : _localityController.text.trim(),
        stateProvince: _stateProvinceController.text.trim().isEmpty
            ? null
            : _stateProvinceController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        email: email.isEmpty ? null : email.toLowerCase(),
        latitude: location.latitude,
        longitude: location.longitude,
        mobilePhone: _mobilePhoneController.text.trim(),
      );

      if (!mounted) return;
      if (widget.persistDraft != null) {
        await widget.persistDraft!(draft);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pop(draft);
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showCellCode = _cellCodeController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? l10n.cellDiscipleTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.header != null) ...[
                  widget.header!,
                  const SizedBox(height: 16),
                ],
                FormSectionTitle(l10n.memberDetailSectionPersonal),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegLastName,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.leaderRegLastNameRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegFirstNames,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.leaderRegFirstNamesRequired
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.memberGender,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: LeaderGender.values.map((g) {
                    return FilterChip(
                      label: Text(g.localizedLabel(l10n)),
                      selected: _gender == g,
                      onSelected: _isSaving
                          ? null
                          : (v) => setState(() => _gender = v ? g : null),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _idDocumentTypeSelector(l10n),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idDocumentNumberController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.memberIdDocumentNumber,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _dateField(
                  label: l10n.leaderRegBirthDate,
                  value: _birthDate != null
                      ? _formatDate(_birthDate!)
                      : l10n.memberSelectDate,
                  onTap: _pickBirthDate,
                  clearDateLabel: l10n.memberClearDate,
                  onClear: _birthDate != null
                      ? () => setState(() => _birthDate = null)
                      : null,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegAge,
                    prefixIcon: const Icon(Icons.cake_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    _ageFromBirthDate(_birthDate) != null
                        ? l10n.memberAgeYears(_ageFromBirthDate(_birthDate)!)
                        : '—',
                  ),
                ),
                const SizedBox(height: 16),
                AddressFieldsSection(
                  streetController: _streetController,
                  streetNumberController: _streetNumberController,
                  neighborhoodController: _neighborhoodController,
                  localityController: _localityController,
                  stateProvinceController: _stateProvinceController,
                  postalCodeController: _postalCodeController,
                  enabled: !_isSaving,
                  onStreetCoordinatesSelected: (location) {
                    setState(() => _location = location);
                  },
                  onAddressCleared: () {
                    setState(() => _location = null);
                  },
                ),
                const SizedBox(height: 24),
                FormSectionTitle(l10n.leaderDetailSectionCellContact),
                if (showCellCode) ...[
                  TextFormField(
                    controller: _cellCodeController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.leaderRegCell,
                      prefixIcon: const Icon(Icons.groups_outlined),
                      border: const OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _mobilePhoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: l10n.leaderDetailMobile,
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.leaderRegMobileRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: l10n.cellDiscipleEmailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.cellDiscipleEmailHelper,
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    if (!value.contains('@')) return l10n.emailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _onSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.commonSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
