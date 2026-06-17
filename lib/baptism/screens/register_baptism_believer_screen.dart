import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../address/services/geocoding_service.dart';
import '../../address/widgets/address_fields_section.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../../leaders/services/leader_service.dart';
import '../../members/models/church_member.dart';
import '../../members/models/id_document_type.dart';
import '../../members/models/marital_status.dart';
import '../../members/models/member_assignment_kind.dart';
import '../../members/models/member_entry_source.dart';
import '../../members/models/member_registration_source.dart';
import '../../members/services/member_service.dart';

class RegisterBaptismBelieverScreen extends StatefulWidget {
  const RegisterBaptismBelieverScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.memberService,
    this.permissions,
    this.actingLeaderId,
  });

  final String registeredBy;
  final String? churchId;
  final MemberService? memberService;
  final AppPermissions? permissions;
  final String? actingLeaderId;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterBaptismBelieverScreen> createState() =>
      _RegisterBaptismBelieverScreenState();
}

class _RegisterBaptismBelieverScreenState
    extends State<RegisterBaptismBelieverScreen> {
  String? get _effectiveChurchId {
    final fromWidget = widget.churchId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    final fromProfile = widget._permissions.churchId?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return null;
  }

  final _formKey = GlobalKey<FormState>();
  final _birthDateFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final _maritalStatusFieldKey = GlobalKey<FormFieldState<MaritalStatus>>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idDocumentNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _localityController = TextEditingController();
  final _stateProvinceController = TextEditingController(text: 'Buenos Aires');
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _volunteerController = TextEditingController();

  late final MemberService _memberService;
  final _leaderService = LeaderService();
  final _geocodingService = GeocodingService();

  DateTime _formDate = DateTime.now();
  DateTime? _birthDate;
  LeaderGender? _gender;
  IdDocumentType? _idDocumentType;
  MaritalStatus? _maritalStatus;
  GeoLocation? _memberLocation;
  bool _includeAddress = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _memberService = widget.memberService ?? MemberService();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idDocumentNumberController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _neighborhoodController.dispose();
    _localityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _volunteerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate({
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
    required void Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickFormDate() async {
    await _pickDate(
      initial: _formDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      onPicked: (date) => setState(() => _formDate = date),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    await _pickDate(
      initial: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      onPicked: (date) {
        setState(() => _birthDate = date);
        _birthDateFieldKey.currentState?.didChange(date);
      },
    );
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearAddressFields() {
    _streetController.clear();
    _streetNumberController.clear();
    _neighborhoodController.clear();
    _localityController.clear();
    _stateProvinceController.text = 'Buenos Aires';
    _postalCodeController.clear();
    _memberLocation = null;
  }

  String _buildFormattedAddress() {
    return [
      _streetController.text.trim(),
      _streetNumberController.text.trim(),
      _neighborhoodController.text.trim(),
      _localityController.text.trim(),
      _stateProvinceController.text.trim(),
      _postalCodeController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;

    if (widget._permissions.isRegistrar &&
        (_effectiveChurchId == null || _effectiveChurchId!.isEmpty)) {
      _showMessage(l10n.memberNoChurchAssigned);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var location = _memberLocation;
      if (location == null && _includeAddress) {
        final address = _buildFormattedAddress();
        if (address.isNotEmpty) {
          location = await _geocodingService.geocodeAddress(address);
        }
      }

      String? assignedLeaderId;
      String? assignedLeaderName;
      String? assignedLeaderCellCode;
      if (widget._permissions.isLeader) {
        assignedLeaderId = widget.actingLeaderId?.trim();
        if (assignedLeaderId != null && assignedLeaderId.isNotEmpty) {
          final leader = await _leaderService.fetchLeaderById(assignedLeaderId);
          assignedLeaderName = leader?.fullName;
          assignedLeaderCellCode = leader?.cellCode;
        }
      }

      final member = ChurchMember(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _gender,
        street: _includeAddress && _streetController.text.trim().isNotEmpty
            ? _streetController.text.trim()
            : null,
        streetNumber:
            _includeAddress && _streetNumberController.text.trim().isNotEmpty
                ? _streetNumberController.text.trim()
                : null,
        neighborhood:
            _includeAddress && _neighborhoodController.text.trim().isNotEmpty
                ? _neighborhoodController.text.trim()
                : null,
        locality: _includeAddress && _localityController.text.trim().isNotEmpty
            ? _localityController.text.trim()
            : null,
        stateProvince: _includeAddress &&
                _stateProvinceController.text.trim().isNotEmpty
            ? _stateProvinceController.text.trim()
            : null,
        postalCode:
            _includeAddress && _postalCodeController.text.trim().isNotEmpty
                ? _postalCodeController.text.trim()
                : null,
        latitude: location?.latitude,
        longitude: location?.longitude,
        phone: _phoneController.text.trim(),
        idDocumentType: _idDocumentType,
        idDocumentNumber: _idDocumentNumberController.text.trim().isEmpty
            ? null
            : _idDocumentNumberController.text.trim(),
        birthDate: _birthDate!,
        occupation: _occupationController.text.trim(),
        maritalStatus: _maritalStatus!,
        volunteer: _volunteerController.text.trim().isEmpty
            ? null
            : _volunteerController.text.trim(),
        assignedLeaderId: assignedLeaderId,
        assignedLeaderName: assignedLeaderName,
        assignedLeaderCellCode: assignedLeaderCellCode,
        assignedLeaderFromRegistration: assignedLeaderId != null,
        assignmentKind: assignedLeaderId != null
            ? MemberAssignmentKind.pastoral
            : null,
        wantsVisit: false,
        isNewBeliever: true,
        isBaptized: false,
        entrySource: MemberEntrySource.iglesiaMadre,
        formDate: _formDate,
        registeredAt: DateTime.now(),
        registeredBy: widget.registeredBy,
        churchId: _effectiveChurchId,
        registrationSource: MemberRegistrationSource.registerBaptismBeliever,
        pastoralAssignedAt:
            assignedLeaderId != null ? DateTime.now() : null,
      );

      final memberId = await _memberService.addMember(
        member,
        notifyLeader: assignedLeaderId != null,
      );

      if (!mounted) return;
      _showMessage(l10n.memberRegisteredSuccess);
      Navigator.of(context).pop(memberId);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(MemberService.messageFromFirestoreException(e, l10n));
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          filled: true,
        ),
        child: Text(
          value,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
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
              onSelected: _isLoading
                  ? null
                  : (selected) => setState(() {
                        _idDocumentType = selected ? type : null;
                      }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _genderSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.memberGender,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: LeaderGender.values.map((gender) {
            return FilterChip(
              label: Text(gender.localizedLabel(l10n)),
              selected: _gender == gender,
              onSelected: _isLoading
                  ? null
                  : (selected) => setState(() {
                        _gender = selected ? gender : null;
                      }),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget._permissions;
    final l10n = context.l10n;

    return RoleGate(
      permissions: permissions,
      allowed: permissions.canRegisterMember,
      deniedMessage: l10n.memberNoPermissionRegister,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.baptismCalendarRegisterBelieverTitle),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dateField(
                    label: l10n.memberFormDate,
                    value: _formatDate(_formDate),
                    onTap: _pickFormDate,
                  ),
                  FormSectionTitle(l10n.memberSectionPersonalData),
                  TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.memberFirstName,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.memberFirstNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.memberLastName,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.memberLastNameRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _idDocumentTypeSelector(l10n),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _idDocumentNumberController,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.memberIdDocumentNumber,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _genderSelector(l10n),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _includeAddress,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _includeAddress = value;
                              if (!value) _clearAddressFields();
                            });
                          },
                    title: Text(l10n.memberIncludeAddress),
                    subtitle: Text(l10n.memberAddressOptional),
                    secondary: const Icon(Icons.location_on_outlined),
                  ),
                  if (_includeAddress) ...[
                    const SizedBox(height: 8),
                    AddressFieldsSection(
                      streetController: _streetController,
                      streetNumberController: _streetNumberController,
                      neighborhoodController: _neighborhoodController,
                      localityController: _localityController,
                      stateProvinceController: _stateProvinceController,
                      postalCodeController: _postalCodeController,
                      enabled: !_isLoading,
                      requireAddress: false,
                      onStreetCoordinatesSelected: (location) {
                        setState(() => _memberLocation = location);
                      },
                      onAddressCleared: () {
                        setState(() => _memberLocation = null);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.memberPhone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.memberPhoneRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FormField<DateTime>(
                    key: _birthDateFieldKey,
                    initialValue: _birthDate,
                    validator: (value) =>
                        value == null ? l10n.memberBirthDateRequired : null,
                    builder: (field) {
                      final age = _ageFromBirthDate(_birthDate);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _dateField(
                            label: l10n.memberBirthDate,
                            value: _birthDate != null
                                ? _formatDate(_birthDate!)
                                : l10n.memberSelectDate,
                            onTap: _pickBirthDate,
                          ),
                          if (field.hasError) ...[
                            const SizedBox(height: 4),
                            Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.memberAge,
                              prefixIcon: const Icon(Icons.cake_outlined),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            child: Text(
                              age != null ? l10n.memberAgeYears(age) : '—',
                              style: TextStyle(
                                color: age != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _occupationController,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.memberOccupation,
                      prefixIcon: const Icon(Icons.work_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.memberOccupationRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FormField<MaritalStatus>(
                    key: _maritalStatusFieldKey,
                    initialValue: _maritalStatus,
                    validator: (value) =>
                        value == null ? l10n.memberMaritalStatusRequired : null,
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.memberMaritalStatus,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: MaritalStatus.values.map((status) {
                              return FilterChip(
                                label: Text(status.localizedLabel(l10n)),
                                selected: _maritalStatus == status,
                                onSelected: _isLoading
                                    ? null
                                    : (selected) {
                                        final picked = selected ? status : null;
                                        setState(() => _maritalStatus = picked);
                                        field.didChange(picked);
                                      },
                              );
                            }).toList(),
                          ),
                          if (field.hasError) ...[
                            const SizedBox(height: 4),
                            Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _volunteerController,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.memberVolunteer,
                      prefixIcon: const Icon(Icons.volunteer_activism_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _onSave,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isLoading
                          ? l10n.memberSaving
                          : l10n.baptismCalendarRegisterBelieverButton,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
