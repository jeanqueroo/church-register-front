import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/locale/weekday_labels.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../models/cell_attendance_record.dart';
import '../models/cell_attendance_session.dart';
import '../models/church_cell.dart';
import '../services/cell_attendance_service.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';

class RegisterCellAttendanceScreen extends StatefulWidget {
  const RegisterCellAttendanceScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.actingLeaderId,
    this.attendanceService,
    this.memberService,
    this.permissions,
  });

  final ChurchCell cell;
  final String registeredBy;
  final String? actingLeaderId;
  final CellAttendanceService? attendanceService;
  final MemberService? memberService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterCellAttendanceScreen> createState() =>
      _RegisterCellAttendanceScreenState();
}

class _RegisterCellAttendanceScreenState
    extends State<RegisterCellAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();
  final _dayChangeReasonController = TextEditingController();
  final _locationChangeReasonController = TextEditingController();
  final _offeringCollectedController = TextEditingController();
  final _observationsController = TextEditingController();

  late final CellAttendanceService _attendanceService;
  late final MemberService _memberService;

  DateTime _sessionDate = DateTime.now();
  TimeOfDay _sessionTime = TimeOfDay.now();
  bool _noteDayChangeForSession = false;
  bool _noteLocationChangeForSession = false;
  bool _loadingMembers = true;
  bool _isSaving = false;
  String? _loadError;
  List<ChurchMember> _members = [];
  final Map<String, bool> _presentByMemberId = {};

  String get _registeredPlace => widget.cell.formattedAddress.trim();

  bool get _dayDiffers =>
      weekdayDiffersFromStored(_sessionDate, widget.cell.cellDay);

  bool get _locationDiffers {
    final registered = _normalize(_registeredPlace);
    final actual = _normalize(_placeController.text);
    if (registered.isEmpty || actual.isEmpty) return false;
    return registered != actual;
  }

  @override
  void initState() {
    super.initState();
    _attendanceService = widget.attendanceService ?? CellAttendanceService();
    _memberService = widget.memberService ?? MemberService();
    _placeController.text = _registeredPlace;
    _placeController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadMembers();
  }

  @override
  void dispose() {
    _placeController.dispose();
    _dayChangeReasonController.dispose();
    _locationChangeReasonController.dispose();
    _offeringCollectedController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _loadMembers() async {
    final cellId = widget.cell.id;
    if (cellId == null || cellId.isEmpty) {
      setState(() {
        _loadingMembers = false;
        _members = [];
      });
      return;
    }

    try {
      final members = await _memberService.fetchMembersInCell(cellId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _presentByMemberId.clear();
        for (final member in members) {
          final id = member.id;
          if (id != null && id.isNotEmpty) {
            _presentByMemberId[id] = true;
          }
        }
        _loadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _loadError = context.l10n.cellAttendanceMembersLoadError;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _sessionDate = picked;
      _noteDayChangeForSession = false;
      _dayChangeReasonController.clear();
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sessionTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _sessionTime = picked);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final cell = widget.cell;
    final cellId = cell.id;
    final leaderId = cell.leaderId?.trim();

    if (cellId == null || cellId.isEmpty) {
      _showMessage(l10n.cellDiscipleCellMissing);
      return;
    }
    if (leaderId == null || leaderId.isEmpty) {
      _showMessage(l10n.cellAttendanceLeaderRequired);
      return;
    }

    if (_dayDiffers &&
        _noteDayChangeForSession &&
        _dayChangeReasonController.text.trim().isEmpty) {
      _showMessage(l10n.cellAttendanceDayReasonRequired);
      return;
    }

    if (_locationDiffers &&
        _noteLocationChangeForSession &&
        _locationChangeReasonController.text.trim().isEmpty) {
      _showMessage(l10n.cellAttendanceLocationReasonRequired);
      return;
    }

    final records = <CellAttendanceRecord>[];
    for (final member in _members) {
      final memberId = member.id;
      if (memberId == null || memberId.isEmpty) continue;
      records.add(
        CellAttendanceRecord(
          memberId: memberId,
          fullName: member.fullName,
          present: _presentByMemberId[memberId] ?? false,
        ),
      );
    }

    final presentCount = records.where((record) => record.present).length;
    final sessionWeekday = weekdayStorageValueFromDate(_sessionDate);
    final now = DateTime.now();

    setState(() => _isSaving = true);
    try {
      await _attendanceService.addSession(
        CellAttendanceSession(
          cellId: cellId,
          cellCode: cell.code,
          sessionDate: DateTime(
            _sessionDate.year,
            _sessionDate.month,
            _sessionDate.day,
          ),
          sessionTime: _formatTime(_sessionTime),
          place: _placeController.text.trim(),
          registeredCellDay: cell.cellDay,
          sessionWeekday: sessionWeekday,
          dayDiffersFromRegistered: _dayDiffers,
          noteDayChangeForSession: _dayDiffers && _noteDayChangeForSession,
          dayChangeReason: _noteDayChangeForSession
              ? _dayChangeReasonController.text.trim()
              : null,
          registeredPlace: _registeredPlace,
          locationDiffersFromRegistered: _locationDiffers,
          noteLocationChangeForSession:
              _locationDiffers && _noteLocationChangeForSession,
          locationChangeReason: _noteLocationChangeForSession
              ? _locationChangeReasonController.text.trim()
              : null,
          offeringCollected: _offeringCollectedController.text.trim().isEmpty
              ? null
              : _offeringCollectedController.text.trim(),
          observations: _observationsController.text.trim().isEmpty
              ? null
              : _observationsController.text.trim(),
          records: records,
          presentCount: presentCount,
          totalCount: records.length,
          leaderId: leaderId,
          leaderName: cell.leaderName,
          registeredAt: now,
          registeredBy: widget.registeredBy,
          churchId: cell.churchId,
        ),
      );

      if (!mounted) return;
      _showMessage(l10n.cellAttendanceSaved);
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(CellAttendanceService.messageFromFirestoreException(e, l10n));
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _dayDifferenceSection(AppLocalizations l10n) {
    if (!_dayDiffers) return const SizedBox.shrink();

    final registeredDay = localizedWeekday(l10n, widget.cell.cellDay);
    final actualDay = localizedWeekday(
      l10n,
      weekdayStorageValueFromDate(_sessionDate),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.cellAttendanceDayDiffersInfo(registeredDay ?? '', actualDay ?? ''),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ),
        SwitchListTile(
          value: _noteDayChangeForSession,
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _noteDayChangeForSession = value),
          title: Text(l10n.cellAttendanceDayChangeSwitch),
          subtitle: Text(l10n.cellAttendanceDayChangeSwitchHint),
        ),
        if (_noteDayChangeForSession) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _dayChangeReasonController,
            enabled: !_isSaving,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.cellAttendanceDayChangeReason,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (!_noteDayChangeForSession) return null;
              if (value == null || value.trim().isEmpty) {
                return l10n.cellAttendanceDayReasonRequired;
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _locationDifferenceSection(AppLocalizations l10n) {
    if (!_locationDiffers) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.cellAttendanceLocationDiffersInfo,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ),
        SwitchListTile(
          value: _noteLocationChangeForSession,
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _noteLocationChangeForSession = value),
          title: Text(l10n.cellAttendanceLocationChangeSwitch),
          subtitle: Text(l10n.cellAttendanceLocationChangeSwitchHint),
        ),
        if (_noteLocationChangeForSession) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationChangeReasonController,
            enabled: !_isSaving,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.cellAttendanceLocationChangeReason,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (!_noteLocationChangeForSession) return null;
              if (value == null || value.trim().isEmpty) {
                return l10n.cellAttendanceLocationReasonRequired;
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _attendanceSection(AppLocalizations l10n) {
    if (_loadingMembers) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _loadError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (_members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.cellDiscipleListEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        for (final id in _presentByMemberId.keys) {
                          _presentByMemberId[id] = true;
                        }
                      });
                    },
              child: Text(l10n.cellAttendanceMarkAllPresent),
            ),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        for (final id in _presentByMemberId.keys) {
                          _presentByMemberId[id] = false;
                        }
                      });
                    },
              child: Text(l10n.cellAttendanceMarkAllAbsent),
            ),
          ],
        ),
        ..._members.map((member) {
          final memberId = member.id;
          if (memberId == null || memberId.isEmpty) {
            return const SizedBox.shrink();
          }
          return CheckboxListTile(
            value: _presentByMemberId[memberId] ?? false,
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _presentByMemberId[memberId] = value ?? false;
                    });
                  },
            title: Text(member.fullName),
            subtitle: Text(member.phone),
            secondary: CircleAvatar(
              child: Text(
                member.fullName.isNotEmpty
                    ? member.fullName[0].toUpperCase()
                    : '?',
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cell = widget.cell;

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canRegisterCellAttendance(
        cell,
        actingLeaderId: widget.actingLeaderId,
      ),
      deniedMessage: l10n.cellAttendanceDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.cellAttendanceRegisterTitle),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.groups_2_outlined),
                      title: Text(cell.displayLabel),
                      subtitle: Text(
                        [
                          if (cell.leaderName != null) cell.leaderName!,
                          if (cell.cellDay != null)
                            '${l10n.cellRegMeetingDay}: ${localizedWeekday(l10n, cell.cellDay)}',
                        ].join(' · '),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.cellAttendanceSectionWhen),
                  InkWell(
                    onTap: _isSaving ? null : _pickDate,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.cellAttendanceSessionDate,
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: const OutlineInputBorder(),
                        filled: true,
                      ),
                      child: Text(_formatDate(_sessionDate)),
                    ),
                  ),
                  _dayDifferenceSection(l10n),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _isSaving ? null : _pickTime,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.cellAttendanceSessionTime,
                        prefixIcon: const Icon(Icons.access_time_outlined),
                        border: const OutlineInputBorder(),
                        filled: true,
                      ),
                      child: Text(_formatTime(_sessionTime)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.cellAttendanceSectionWhere),
                  TextFormField(
                    controller: _placeController,
                    enabled: !_isSaving,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.cellAttendanceSessionPlace,
                      hintText: l10n.cellAttendanceSessionPlaceHint,
                      prefixIcon: const Icon(Icons.place_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? l10n.cellAttendancePlaceRequired
                            : null,
                  ),
                  _locationDifferenceSection(l10n),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.cellAttendanceSectionNotes),
                  TextFormField(
                    controller: _offeringCollectedController,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.cellAttendanceOfferingCollected,
                      hintText: l10n.cellAttendanceOfferingCollectedHint,
                      prefixIcon: const Icon(Icons.volunteer_activism_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _observationsController,
                    enabled: !_isSaving,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.cellAttendanceObservations,
                      hintText: l10n.cellAttendanceObservationsHint,
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSectionTitle(l10n.cellAttendanceSectionRoll),
                  Text(
                    l10n.cellAttendanceSectionRollHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _attendanceSection(l10n),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isSaving || _loadingMembers ? null : _onSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSaving
                          ? l10n.memberSaving
                          : l10n.cellAttendanceSaveAction,
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
