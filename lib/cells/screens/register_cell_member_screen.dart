import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../address/widgets/address_fields_section.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/locale/weekday_labels.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/models/marital_status.dart';
import '../../members/models/member_assignment_kind.dart';
import '../../members/models/member_entry_source.dart';
import '../../members/services/member_service.dart';
import '../cell_leader_gender.dart';
import '../cell_member_capacity.dart';
import '../models/church_cell.dart';

class RegisterCellMemberScreen extends StatefulWidget {
  const RegisterCellMemberScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.churchId,
    this.memberService,
    this.permissions,
    this.actingLeaderId,
  });

  final ChurchCell cell;
  final String registeredBy;
  final String? churchId;
  final MemberService? memberService;
  final AppPermissions? permissions;
  final String? actingLeaderId;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterCellMemberScreen> createState() =>
      _RegisterCellMemberScreenState();
}

class _RegisterCellMemberScreenState extends State<RegisterCellMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final _maritalStatusFieldKey = GlobalKey<FormFieldState<MaritalStatus>>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _observationsController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _localityController = TextEditingController();
  final _stateProvinceController = TextEditingController(text: 'Buenos Aires');
  final _postalCodeController = TextEditingController();

  late final MemberService _memberService;

  LeaderGender? _gender;
  LeaderGender? _cellLeaderGender;
  bool _loadingLeaderGender = true;
  DateTime? _birthDate;
  MaritalStatus? _maritalStatus;
  GeoLocation? _memberLocation;
  bool _wantsVisit = false;
  bool _isSaving = false;

  String? get _effectiveChurchId {
    final fromWidget = widget.churchId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    final fromCell = widget.cell.churchId?.trim();
    if (fromCell != null && fromCell.isNotEmpty) return fromCell;
    return widget._permissions.churchId?.trim();
  }

  bool get _cellHasLeader {
    final leaderId = widget.cell.leaderId?.trim();
    return leaderId != null && leaderId.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _memberService = widget.memberService ?? MemberService();
    _loadCellLeaderGender();
  }

  Future<void> _loadCellLeaderGender() async {
    try {
      final gender = await fetchCellLeaderGender(widget.cell);
      if (!mounted) return;
      setState(() {
        _cellLeaderGender = gender;
        if (gender != null) _gender = gender;
        _loadingLeaderGender = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLeaderGender = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _observationsController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _neighborhoodController.dispose();
    _localityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    if (picked != null) {
      setState(() => _birthDate = picked);
      _birthDateFieldKey.currentState?.didChange(picked);
    }
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

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final cell = widget.cell;
    final cellId = cell.id;

    if (cellId == null || cellId.isEmpty) {
      _showMessage(l10n.cellDiscipleCellMissing);
      return;
    }

    if (widget._permissions.isRegistrar &&
        (_effectiveChurchId == null || _effectiveChurchId!.isEmpty)) {
      _showMessage(l10n.memberNoChurchAssigned);
      return;
    }

    if (_wantsVisit && !_cellHasLeader) {
      _showMessage(l10n.cellMemberVisitNoLeader);
      return;
    }

    if (_cellLeaderGender == null) {
      _showMessage(l10n.cellMemberAssignLeaderGenderMissing);
      return;
    }

    if (!memberMatchesCellLeaderGender(
      memberGender: _gender,
      leaderGender: _cellLeaderGender,
    )) {
      _showMessage(l10n.cellMemberAssignGenderMismatch);
      return;
    }

    final currentCount = await _memberService.countMembersInCell(cellId);
    if (!widget._permissions.canRegisterNewCellMember(
      cell,
      currentMemberCount: currentCount,
      actingLeaderId: widget.actingLeaderId,
    )) {
      _showMessage(MemberService.messageForCellAssignmentLeaderOnly(l10n));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final assignCellLeader = _wantsVisit && _cellHasLeader;
      final leaderId = assignCellLeader ? cell.leaderId!.trim() : null;
      final leaderName = assignCellLeader ? cell.leaderName?.trim() : null;
      final leaderCellCode = assignCellLeader ? cell.code.trim() : null;

      final member = ChurchMember(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _gender,
        street: _streetController.text.trim().isEmpty
            ? null
            : _streetController.text.trim(),
        streetNumber: _streetNumberController.text.trim().isEmpty
            ? null
            : _streetNumberController.text.trim(),
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
        latitude: _memberLocation?.latitude,
        longitude: _memberLocation?.longitude,
        phone: _phoneController.text.trim(),
        birthDate: _birthDate,
        occupation: _occupationController.text.trim(),
        maritalStatus: _maritalStatus,
        cellDay: cell.cellDay,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        assignedLeaderId: leaderId,
        assignedLeaderName: leaderName,
        assignedLeaderCellCode: leaderCellCode,
        assignedLeaderFromRegistration: false,
        assignmentKind: MemberAssignmentKind.cell,
        wantsVisit: _wantsVisit,
        isNewBeliever: true,
        entrySource: MemberEntrySource.celula,
        formDate: now,
        registeredAt: now,
        registeredBy: widget.registeredBy,
        churchId: _effectiveChurchId,
      );

      final memberId = await _memberService.addMember(
        member,
        notifyLeader: false,
      );
      final capacityExceeded = await _memberService.assignMemberToCell(
        member: ChurchMember(
          id: memberId,
          firstName: member.firstName,
          lastName: member.lastName,
          phone: member.phone,
          gender: member.gender,
          formDate: member.formDate,
          registeredAt: member.registeredAt,
          registeredBy: member.registeredBy,
          assignedLeaderId: member.assignedLeaderId,
          churchId: member.churchId,
        ),
        cell: cell,
        actingLeaderId: widget.actingLeaderId,
        requiredLeaderGender: _cellLeaderGender,
        allowExceedCapacityForNewRegistration: true,
      );

      if (!mounted) return;
      if (capacityExceeded) {
        _showMessage(l10n.cellMemberCapacityAdminNotified);
      } else if (assignCellLeader && leaderName != null) {
        _showMessage(
          l10n.cellMemberRegisteredWithCellLeader(
            member.fullName,
            cell.displayLabel,
            leaderName,
          ),
        );
      } else {
        _showMessage(
          l10n.cellMemberRegisteredAndAssigned(
            member.fullName,
            cell.displayLabel,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } on CellAssignmentLeaderOnlyException {
      if (!mounted) return;
      _showMessage(MemberService.messageForCellAssignmentLeaderOnly(l10n));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(MemberService.messageFromFirestoreException(e, l10n));
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _cellInfoCard(AppLocalizations l10n) {
    final cell = widget.cell;
    final rows = <({String label, String? value})>[
      (label: l10n.cellRegCode, value: cell.code),
      (label: l10n.cellRegName, value: cell.name),
      (
        label: l10n.cellRegMeetingDay,
        value: localizedWeekday(l10n, cell.cellDay),
      ),
      (label: l10n.cellRegSectionLeader, value: cell.leaderName),
    ].where((row) => row.value != null && row.value!.trim().isNotEmpty);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cell.displayLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _genderSelector(AppLocalizations l10n) {
    final lockedGender = _cellLeaderGender;
    final genders = lockedGender != null
        ? [lockedGender]
        : LeaderGender.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.memberGender,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        if (lockedGender != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.cellMemberRegisterGenderLocked(
              lockedGender.localizedLabel(l10n),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 8),
        if (_loadingLeaderGender)
          const LinearProgressIndicator()
        else
          Wrap(
            spacing: 8,
            children: genders.map((gender) {
              return FilterChip(
                label: Text(gender.localizedLabel(l10n)),
                selected: _gender == gender,
                onSelected: lockedGender != null || _isSaving
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

  Widget _maritalStatusSelector(AppLocalizations l10n) {
    return FormField<MaritalStatus>(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: MaritalStatus.values.map((status) {
                final selected = _maritalStatus == status;
                return FilterChip(
                  label: Text(status.localizedLabel(l10n)),
                  selected: selected,
                  onSelected: _isSaving
                      ? null
                      : (value) {
                          final picked = value ? status : null;
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
    );
  }

  Widget _birthDateField(AppLocalizations l10n) {
    final age = _ageFromBirthDate(_birthDate);
    return FormField<DateTime>(
      key: _birthDateFieldKey,
      initialValue: _birthDate,
      validator: (value) =>
          value == null ? l10n.memberBirthDateRequired : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _isSaving ? null : _pickBirthDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.memberBirthDate,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  errorText: field.hasError ? field.errorText : null,
                ),
                child: Text(
                  _birthDate != null
                      ? _formatDate(_birthDate!)
                      : l10n.memberSelectDate,
                  style: TextStyle(
                    color: _birthDate != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (age != null) ...[
              const SizedBox(height: 16),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.memberAge,
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Text(l10n.memberAgeYears(age)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _visitSection(AppLocalizations l10n) {
    final cell = widget.cell;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionTitle(l10n.memberSectionVisit),
        SwitchListTile(
          value: _wantsVisit,
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _wantsVisit = value),
          title: Text(l10n.memberWantsVisit),
          subtitle: Text(l10n.cellMemberWantsVisitSubtitle),
          secondary: const Icon(Icons.home_outlined),
        ),
        if (_wantsVisit) ...[
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.supervisor_account_outlined,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _cellHasLeader
                          ? l10n.cellMemberVisitLeaderHint(
                              cell.leaderName ?? cell.leaderId!,
                              cell.displayLabel,
                            )
                          : l10n.cellMemberVisitNoLeader,
                      style: TextStyle(
                        color: _cellHasLeader
                            ? Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canRegisterMember,
      deniedMessage: l10n.memberNoPermissionRegister,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.cellMemberRegisterTitle),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cellInfoCard(l10n),
                  const SizedBox(height: 16),
                  Text(
                    l10n.cellMemberFormHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.memberSectionPersonalData),
                  TextFormField(
                    controller: _firstNameController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.words,
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
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.memberLastName,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.memberLastNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.phone,
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
                  _genderSelector(l10n),
                  const SizedBox(height: 16),
                  _birthDateField(l10n),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _occupationController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.words,
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
                  _maritalStatusSelector(l10n),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.memberDetailSectionAddress),
                  AddressFieldsSection(
                    streetController: _streetController,
                    streetNumberController: _streetNumberController,
                    neighborhoodController: _neighborhoodController,
                    localityController: _localityController,
                    stateProvinceController: _stateProvinceController,
                    postalCodeController: _postalCodeController,
                    enabled: !_isSaving,
                    requireAddress: _wantsVisit,
                    onStreetCoordinatesSelected: (location) {
                      setState(() => _memberLocation = location);
                    },
                    onAddressCleared: () {
                      setState(() => _memberLocation = null);
                    },
                  ),
                  const SizedBox(height: 24),
                  _visitSection(l10n),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.memberSectionObservations),
                  TextFormField(
                    controller: _observationsController,
                    enabled: !_isSaving,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l10n.memberObservationsHint,
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
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
                        : const Icon(Icons.group_add_outlined),
                    label: Text(
                      _isSaving
                          ? l10n.memberSaving
                          : l10n.cellMemberFormSubmit,
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
