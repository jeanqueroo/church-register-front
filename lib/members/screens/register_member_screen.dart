import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../address/services/geocoding_service.dart';
import '../../address/widgets/address_fields_section.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/widgets/church_display_name.dart';
import '../../core/widgets/form_section_title.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
import '../../leaders/widgets/leader_search_field.dart';
import '../models/church_member.dart';
import '../models/marital_status.dart';
import '../services/leader_assignment_service.dart';
import '../services/member_service.dart';

class RegisterMemberScreen extends StatefulWidget {
  const RegisterMemberScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.memberService,
    this.memberToEdit,
    this.permissions,
  });

  final String registeredBy;
  /// Iglesia del usuario que registra (admin / registrador).
  final String? churchId;
  final MemberService? memberService;
  final ChurchMember? memberToEdit;
  final AppPermissions? permissions;

  bool get isEditing => memberToEdit != null;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterMemberScreen> createState() => _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends State<RegisterMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateFieldKey = GlobalKey<FormFieldState<DateTime>>();
  final _maritalStatusFieldKey = GlobalKey<FormFieldState<MaritalStatus>>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _localityController = TextEditingController();
  final _stateProvinceController = TextEditingController(text: 'Buenos Aires');
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _cellTimeController = TextEditingController();
  final _cellZoneController = TextEditingController();
  final _observationsController = TextEditingController();
  final _volunteerController = TextEditingController();

  late final MemberService _memberService;
  final _leaderService = LeaderService();
  final _geocodingService = GeocodingService();
  final _assignmentService = LeaderAssignmentService();

  DateTime _formDate = DateTime.now();
  DateTime? _birthDate;
  LeaderGender? _gender;
  MaritalStatus? _maritalStatus;
  String? _cellDay;
  GeoLocation? _memberLocation;
  bool _wantsVisit = true;
  bool _manualLeader = false;
  bool _isLoading = false;
  bool _loadingLeaders = true;
  List<ChurchLeader> _leaders = [];
  ChurchLeader? _selectedLeader;
  String? _pendingLeaderId;

  static const _weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _memberService = widget.memberService ?? MemberService();
    if (widget.memberToEdit != null) {
      _loadMember(widget.memberToEdit!);
    }
    _loadLeaders();
  }

  Future<void> _loadLeaders() async {
    try {
      final leaders =
          await _leaderService.fetchAssignableLeaders(churchId: widget.churchId);
      leaders.sort((a, b) => a.fullName.compareTo(b.fullName));
      if (!mounted) return;

      ChurchLeader? selected;
      final pendingId = _pendingLeaderId;
      if (pendingId != null) {
        for (final leader in leaders) {
          if (leader.id == pendingId) {
            selected = leader;
            break;
          }
        }
      }

      setState(() {
        _leaders = leaders;
        _loadingLeaders = false;
        _selectedLeader = selected;
        if (selected != null) {
          _manualLeader = true;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingLeaders = false);
      }
    }
  }

  List<ChurchLeader> get _leadersForPicker {
    if (_gender == null) return _leaders;
    return _leaders
        .where((l) => l.gender == null || l.gender == _gender)
        .toList();
  }

  void _loadMember(ChurchMember member) {
    _firstNameController.text = member.firstName;
    _lastNameController.text = member.lastName;
    _streetController.text = member.street ?? '';
    _streetNumberController.text = member.streetNumber ?? '';
    _neighborhoodController.text = member.neighborhood ?? '';
    _localityController.text = member.locality ?? '';
    _stateProvinceController.text = member.stateProvince ?? 'Buenos Aires';
    _postalCodeController.text = member.postalCode ?? '';
    _phoneController.text = member.phone;
    _occupationController.text = member.occupation ?? '';
    _cellTimeController.text = member.cellTime ?? '';
    _cellZoneController.text = member.cellZone ?? '';
    _observationsController.text = member.observations ?? '';
    _volunteerController.text = member.volunteer ?? '';
    _formDate = member.formDate;
    _birthDate = member.birthDate;
    _gender = member.gender;
    _maritalStatus = member.maritalStatus;
    _cellDay = member.cellDay;
    _wantsVisit = member.wantsVisit;
    if (member.assignedLeaderId != null) {
      _pendingLeaderId = member.assignedLeaderId;
      _manualLeader = true;
    }
    if (member.latitude != null && member.longitude != null) {
      _memberLocation = GeoLocation(
        latitude: member.latitude!,
        longitude: member.longitude!,
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _neighborhoodController.dispose();
    _localityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _cellTimeController.dispose();
    _cellZoneController.dispose();
    _observationsController.dispose();
    _volunteerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
      onPicked: (d) => setState(() => _formDate = d),
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    await _pickDate(
      initial: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      onPicked: (d) {
        setState(() => _birthDate = d);
        _birthDateFieldKey.currentState?.didChange(d);
      },
    );
  }

  Future<void> _pickCellTime() async {
    TimeOfDay initial = TimeOfDay.now();
    final parts = _cellTimeController.text.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        initial = TimeOfDay(hour: h, minute: m);
      }
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      _cellTimeController.text = _formatTime(picked);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : onClear,
              child: const Text('Quitar fecha'),
            ),
          ),
        ],
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

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_manualLeader && _selectedLeader == null) {
      _showMessage('Selecciona un líder de la lista');
      return;
    }

    if (!_manualLeader && _wantsVisit && _gender == null) {
      _showMessage('Selecciona el género para asignar un líder automático');
      return;
    }

    setState(() => _isLoading = true);

    try {
      var location = _memberLocation;
      if (location == null) {
        final address = _buildFormattedAddress();
        if (address.isNotEmpty) {
          location = await _geocodingService.geocodeAddress(address);
        }
      }

      String? assignedLeaderId;
      String? assignedLeaderName;
      String? assignedLeaderCellCode;
      double? assignedDistanceKm;
      ChurchLeader? assignedLeader;

      if (_manualLeader) {
        assignedLeader = _selectedLeader;
        assignedLeaderId = assignedLeader?.id;
        assignedLeaderName = assignedLeader?.fullName;
        assignedLeaderCellCode = assignedLeader?.cellCode;
        if (location != null && assignedLeader != null) {
          assignedDistanceKm = await _assignmentService.distanceKmToLeader(
            memberLocation: location,
            leader: assignedLeader,
          );
        }
      } else if (_wantsVisit) {
        if (location == null) {
          if (mounted) {
            _showMessage(
              'No se pudo ubicar la dirección. Selecciónala del autocompletado.',
            );
          }
          return;
        }

        final assignment = await _assignmentService.assignNearestLeader(
          gender: _gender!,
          memberLocation: location,
          churchId: widget.churchId,
        );
        if (assignment != null) {
          assignedLeader = assignment.leader;
          assignedLeaderId = assignment.leader.id;
          assignedLeaderName = assignment.leader.fullName;
          assignedLeaderCellCode = assignment.leader.cellCode;
          assignedDistanceKm = assignment.distanceKm;
        }
      }

      final member = ChurchMember(
        id: widget.memberToEdit?.id,
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
        latitude: location?.latitude,
        longitude: location?.longitude,
        phone: _phoneController.text.trim(),
        birthDate: _birthDate!,
        occupation: _occupationController.text.trim(),
        maritalStatus: _maritalStatus!,
        cellDay: _cellDay,
        cellTime: _cellTimeController.text.trim().isEmpty
            ? null
            : _cellTimeController.text.trim(),
        cellZone: _cellZoneController.text.trim().isEmpty
            ? null
            : _cellZoneController.text.trim(),
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        volunteer: _volunteerController.text.trim().isEmpty
            ? null
            : _volunteerController.text.trim(),
        assignedLeaderId: assignedLeaderId,
        assignedLeaderName: assignedLeaderName,
        assignedLeaderCellCode: assignedLeaderCellCode,
        assignedDistanceKm: assignedDistanceKm,
        wantsVisit: _wantsVisit,
        formDate: _formDate,
        registeredAt: widget.memberToEdit?.registeredAt ?? DateTime.now(),
        registeredBy: widget.memberToEdit?.registeredBy ?? widget.registeredBy,
        churchId: widget.memberToEdit?.churchId ?? widget.churchId,
      );

      if (widget.isEditing) {
        await _memberService.updateMember(
          member,
          previousAssignedLeaderId:
              widget.memberToEdit?.assignedLeaderId,
        );
      } else {
        await _memberService.addMember(member);
      }

      if (!mounted) return;

      if (widget.isEditing) {
        _showMessage('Creyente actualizado correctamente');
      } else if (assignedLeaderName != null) {
        final cellText = assignedLeaderCellCode != null
            ? ' (Célula $assignedLeaderCellCode)'
            : '';
        final distanceText = assignedDistanceKm != null
            ? ' · ${assignedDistanceKm.toStringAsFixed(1)} km'
            : '';
        _showMessage(
          'Creyente registrado. Líder: '
          '$assignedLeaderName$cellText$distanceText',
        );
      } else if (_wantsVisit && !_manualLeader) {
        _showMessage(
          'Creyente registrado. No hay líder del mismo género con dirección cercana.',
        );
      } else {
        _showMessage('Creyente registrado correctamente');
      }
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(MemberService.messageFromFirestoreException(e));
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Error inesperado al guardar.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _leaderAssignmentSection() {
    final filtered = _leadersForPicker;
    final pickerLeaders = filtered.isNotEmpty ? filtered : _leaders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormSectionTitle('LÍDER ASIGNADO'),
        SwitchListTile(
          value: _manualLeader,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _manualLeader = value;
                    if (!value) {
                      _selectedLeader = null;
                    } else if (_selectedLeader != null &&
                        !pickerLeaders.any((l) => l.id == _selectedLeader!.id)) {
                      _selectedLeader = null;
                    }
                  });
                },
          title: const Text('Elegir líder manualmente'),
          subtitle: Text(
            _manualLeader
                ? 'Busca y elige un líder escribiendo su nombre'
                : _wantsVisit
                    ? 'Se asignará el líder más cercano del mismo género'
                    : 'Sin líder hasta que actives visita o elijas uno',
          ),
          secondary: const Icon(Icons.supervisor_account_outlined),
        ),
        if (_manualLeader) ...[
          const SizedBox(height: 8),
          if (_loadingLeaders)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_leaders.isEmpty)
            Text(
              'No hay líderes con rol de líder en la app. '
              'Asigna el rol Líder al registrar un líder.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          else
            LeaderSearchField(
              key: ValueKey('leader-search-${_selectedLeader?.id ?? 'none'}'),
              leaders: pickerLeaders,
              selectedLeader: _selectedLeader,
              enabled: !_isLoading,
              onLeaderSelected: (leader) =>
                  setState(() => _selectedLeader = leader),
              validator: (value) =>
                  _manualLeader && value == null ? 'Selecciona un líder' : null,
            ),
          if (_gender != null && pickerLeaders.length < _leaders.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Mostrando líderes compatibles con el género seleccionado.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _genderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _wantsVisit ? 'Género *' : 'Género',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: LeaderGender.values.map((g) {
            return FilterChip(
              label: Text(g.label),
              selected: _gender == g,
              onSelected: _isLoading
                  ? null
                  : (v) => setState(() {
                        _gender = v ? g : null;
                        if (_selectedLeader?.gender != null &&
                            _gender != null &&
                            _selectedLeader!.gender != _gender) {
                          _selectedLeader = null;
                        }
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
    return RoleGate(
      permissions: permissions,
      allowed: widget.isEditing
          ? permissions.canManageAll
          : permissions.canRegisterMember,
      deniedMessage: widget.isEditing
          ? 'Solo el administrador puede editar creyentes.'
          : 'No tienes permiso para registrar creyentes.',
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Editar creyente'
              : 'Registro de nuevo creyente',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChurchDisplayName(
                  churchId: widget.churchId,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _dateField(
                  label: 'Fecha',
                  value: _formatDate(_formDate),
                  onTap: _pickFormDate,
                ),
                const FormSectionTitle('DATOS PERSONALES'),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa los apellidos'
                      : null,
                ),
                const SizedBox(height: 12),
                _genderSelector(),
                const SizedBox(height: 16),
                AddressFieldsSection(
                  streetController: _streetController,
                  streetNumberController: _streetNumberController,
                  neighborhoodController: _neighborhoodController,
                  localityController: _localityController,
                  stateProvinceController: _stateProvinceController,
                  postalCodeController: _postalCodeController,
                  enabled: !_isLoading,
                  initialSearchText: widget.memberToEdit?.formattedAddress,
                  onStreetCoordinatesSelected: (location) {
                    setState(() => _memberLocation = location);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa el teléfono' : null,
                ),
                const SizedBox(height: 16),
                FormField<DateTime>(
                  key: _birthDateFieldKey,
                  initialValue: _birthDate,
                  validator: (value) =>
                      value == null ? 'Selecciona la fecha de nacimiento' : null,
                  builder: (field) {
                    final age = _ageFromBirthDate(_birthDate);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _dateField(
                          label: 'Fecha de nacimiento *',
                          value: _birthDate != null
                              ? _formatDate(_birthDate!)
                              : 'Seleccionar fecha',
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
                            labelText: 'Edad *',
                            prefixIcon: const Icon(Icons.cake_outlined),
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            errorText: age == null && field.hasError
                                ? ' '
                                : null,
                          ),
                          child: Text(
                            age != null ? '$age años' : '—',
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
                  decoration: const InputDecoration(
                    labelText: 'Ocupación *',
                    prefixIcon: Icon(Icons.work_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa la ocupación'
                      : null,
                ),
                const SizedBox(height: 12),
                FormField<MaritalStatus>(
                  key: _maritalStatusFieldKey,
                  initialValue: _maritalStatus,
                  validator: (value) =>
                      value == null ? 'Selecciona el estado civil' : null,
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Estado civil *',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              label: Text(status.label),
                              selected: selected,
                              onSelected: _isLoading
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
                ),
                const FormSectionTitle('HORARIO PARA CÉLULA'),
                DropdownButtonFormField<String>(
                  initialValue: _cellDay,
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    prefixIcon: Icon(Icons.event_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _weekDays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _cellDay = v),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isLoading ? null : _pickCellTime,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Horario',
                      prefixIcon: Icon(Icons.access_time_outlined),
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    child: Text(
                      _cellTimeController.text.isEmpty
                          ? 'Seleccionar hora'
                          : _cellTimeController.text,
                      style: TextStyle(
                        color: _cellTimeController.text.isEmpty
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cellZoneController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Zona',
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const FormSectionTitle('VISITA'),
                SwitchListTile(
                  value: _wantsVisit,
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _wantsVisit = value),
                  title: const Text('Desea ser visitado'),
                  subtitle: const Text(
                    'Indica si la persona solicita una visita domiciliaria',
                  ),
                  secondary: const Icon(Icons.home_outlined),
                ),
                const SizedBox(height: 8),
                _leaderAssignmentSection(),
                const FormSectionTitle('OBSERVACIONES'),
                TextFormField(
                  controller: _observationsController,
                  enabled: !_isLoading,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Notas adicionales...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _volunteerController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Voluntario',
                    prefixIcon: Icon(Icons.volunteer_activism_outlined),
                    border: OutlineInputBorder(),
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
                        ? 'Guardando...'
                        : widget.isEditing
                            ? 'Guardar cambios'
                            : 'Registrar creyente',
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
