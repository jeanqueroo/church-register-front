import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../address/widgets/address_fields_section.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/geo_location.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
import '../../leaders/widgets/leader_search_field.dart';
import '../models/church_cell.dart';
import '../services/cell_service.dart';

class RegisterCellScreen extends StatefulWidget {
  const RegisterCellScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.cellToEdit,
    this.cellService,
    this.leaderService,
    this.permissions,
    this.ensureLeaderId,
  });

  final String registeredBy;
  final String? churchId;
  final ChurchCell? cellToEdit;
  final CellService? cellService;
  final LeaderService? leaderService;
  final AppPermissions? permissions;
  /// Líder que debe aparecer en el selector aunque esté filtrado (p. ej. titular actual).
  final String? ensureLeaderId;

  bool get isEditing => cellToEdit != null;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterCellScreen> createState() => _RegisterCellScreenState();
}

class _RegisterCellScreenState extends State<RegisterCellScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _localityController = TextEditingController();
  final _stateProvinceController = TextEditingController(text: 'Buenos Aires');
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();

  late final CellService _cellService;
  late final LeaderService _leaderService;

  List<ChurchLeader> _leaders = [];
  ChurchLeader? _selectedLeader;
  GeoLocation? _cellLocation;
  String? _cellDay;
  bool _loadingLeaders = true;
  bool _isSaving = false;

  static const _cellDayStorageValues = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  List<({String value, String label})> _cellDayOptions(AppLocalizations l10n) =>
      [
        (value: _cellDayStorageValues[0], label: l10n.weekdayMonday),
        (value: _cellDayStorageValues[1], label: l10n.weekdayTuesday),
        (value: _cellDayStorageValues[2], label: l10n.weekdayWednesday),
        (value: _cellDayStorageValues[3], label: l10n.weekdayThursday),
        (value: _cellDayStorageValues[4], label: l10n.weekdayFriday),
        (value: _cellDayStorageValues[5], label: l10n.weekdaySaturday),
        (value: _cellDayStorageValues[6], label: l10n.weekdaySunday),
      ];

  @override
  void initState() {
    super.initState();
    _cellService = widget.cellService ?? CellService();
    _leaderService = widget.leaderService ?? LeaderService();
    _prefillFromCell(widget.cellToEdit);
    _loadLeaders();
  }

  void _prefillFromCell(ChurchCell? cell) {
    if (cell == null) return;
    _codeController.text = cell.code;
    _nameController.text = cell.name ?? '';
    _streetController.text = cell.street ?? '';
    _streetNumberController.text = cell.streetNumber ?? '';
    _neighborhoodController.text = cell.neighborhood ?? '';
    _localityController.text = cell.locality ?? '';
    _stateProvinceController.text = cell.stateProvince ?? 'Buenos Aires';
    _postalCodeController.text = cell.postalCode ?? '';
    _notesController.text = cell.notes ?? '';
    _cellDay = cell.cellDay;
    _cellLocation = cell.geoLocation;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _neighborhoodController.dispose();
    _localityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? get _effectiveChurchId {
    final fromWidget = widget.churchId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return widget.cellToEdit?.churchId?.trim();
  }

  bool _isLeaderValidForCell(ChurchLeader? leader) {
    if (leader == null) return false;
    return leader.belongsToChurch(_effectiveChurchId);
  }

  Future<void> _loadLeaders() async {
    try {
      final busyLeaderIds = await _cellService.fetchLeaderIdsWithAssignedCell(
        churchId: _effectiveChurchId,
        excludeCellId: widget.cellToEdit?.id,
      );
      final ensureLeaderId =
          widget.cellToEdit?.leaderId?.trim() ?? widget.ensureLeaderId?.trim();
      final activeLeaders = await _leaderService.fetchLeadersForCellLeaderPicker(
        churchId: _effectiveChurchId,
        busyLeaderIds: busyLeaderIds,
        ensureLeaderId: ensureLeaderId,
      );
      if (!mounted) return;
      ChurchLeader? selectedLeader;
      final leaderId = widget.cellToEdit?.leaderId;
      if (leaderId != null && leaderId.isNotEmpty) {
        for (final leader in activeLeaders) {
          if (leader.id == leaderId) {
            selectedLeader = leader;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _leaders = activeLeaders;
        _selectedLeader = selectedLeader;
        _loadingLeaders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLeaders = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final code = _codeController.text.trim();
    final churchId = _effectiveChurchId;

    if (!_isLeaderValidForCell(_selectedLeader)) {
      _showMessage(l10n.cellRegLeaderWrongChurch);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final exists = await _cellService.codeExists(
        code: code,
        churchId: churchId,
        excludeId: widget.cellToEdit?.id,
      );
      if (exists) {
        if (!mounted) return;
        _showMessage(l10n.cellRegCodeDuplicate);
        return;
      }

      final existing = widget.cellToEdit;
      final cell = ChurchCell(
        id: existing?.id,
        code: code,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
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
        latitude: _cellLocation?.latitude,
        longitude: _cellLocation?.longitude,
        cellDay: _cellDay,
        leaderId: _selectedLeader?.id,
        leaderName: _selectedLeader?.fullName,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        helpers: existing?.helpers ?? const [],
        registeredAt: existing?.registeredAt ?? DateTime.now(),
        registeredBy: existing?.registeredBy ?? widget.registeredBy,
        churchId: churchId,
        memberCount: existing?.memberCount,
        isBlocked: existing?.isBlocked ?? false,
      );

      if (widget.isEditing) {
        final cellId = existing!.id;
        if (cellId == null || cellId.isEmpty) {
          _showMessage(l10n.cellDiscipleCellMissing);
          return;
        }
        await _cellService.updateCell(
          cellId: cellId,
          cell: cell,
          previousCode: existing.code,
        );
        if (!mounted) return;
        _showMessage(l10n.cellEditSuccess);
        Navigator.of(context).pop(true);
        return;
      }

      await _cellService.addCell(cell);
      if (!mounted) return;
      _showMessage(l10n.cellRegSuccess);
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(CellService.messageFromFirestoreException(e, l10n));
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
    final cellDayOptions = _cellDayOptions(l10n);

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget.isEditing
          ? widget._permissions.canEditCell
          : widget._permissions.canRegisterCell,
      deniedMessage:
          widget.isEditing ? l10n.cellEditDenied : l10n.cellRegDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? l10n.cellEditTitle : l10n.cellRegTitle,
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
                  FormSectionTitle(l10n.cellRegSectionData),
                  TextFormField(
                    controller: _codeController,
                    enabled: !_isSaving,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.cellRegCode,
                      hintText: l10n.cellRegCodeHint,
                      prefixIcon: const Icon(Icons.tag_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.cellRegCodeRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.cellRegName,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.cellRegSectionMeeting),
                  DropdownButtonFormField<String>(
                    initialValue: _cellDay,
                    decoration: InputDecoration(
                      labelText: l10n.cellRegMeetingDay,
                      prefixIcon: const Icon(Icons.event_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    items: cellDayOptions
                        .map(
                          (day) => DropdownMenuItem(
                            value: day.value,
                            child: Text(day.label),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _cellDay = value),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? l10n.cellRegMeetingDayRequired
                            : null,
                  ),
                  const SizedBox(height: 24),
                  AddressFieldsSection(
                    streetController: _streetController,
                    streetNumberController: _streetNumberController,
                    neighborhoodController: _neighborhoodController,
                    localityController: _localityController,
                    stateProvinceController: _stateProvinceController,
                    postalCodeController: _postalCodeController,
                    enabled: !_isSaving,
                    requireAddress: true,
                    onStreetCoordinatesSelected: (location) {
                      setState(() => _cellLocation = location);
                    },
                    onAddressCleared: () {
                      setState(() => _cellLocation = null);
                    },
                  ),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.cellRegSectionLeader),
                  if (_loadingLeaders)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else
                    LeaderSearchField(
                      key: ValueKey(
                        'cell-leader-search-${_selectedLeader?.id ?? 'none'}',
                      ),
                      leaders: _leaders,
                      selectedLeader: _selectedLeader,
                      enabled: !_isSaving,
                      onLeaderSelected: (leader) {
                        setState(() => _selectedLeader = leader);
                      },
                      validator: (leader) => leader == null
                          ? l10n.cellRegLeaderRequired
                          : null,
                    ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _notesController,
                    enabled: !_isSaving,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.cellRegNotes,
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: const OutlineInputBorder(),
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
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.commonSave),
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
