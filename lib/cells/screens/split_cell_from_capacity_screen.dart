import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../address/widgets/address_fields_section.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/services/member_service.dart';
import '../cell_leader_gender.dart';
import '../models/church_cell.dart';
import '../services/cell_service.dart';
import '../services/cell_split_service.dart';

class SplitCellFromCapacityScreen extends StatefulWidget {
  const SplitCellFromCapacityScreen({
    super.key,
    required this.sourceCellId,
    required this.registeredBy,
    this.churchId,
    this.permissions,
    this.cellService,
    this.memberService,
    this.splitService,
  });

  final String sourceCellId;
  final String registeredBy;
  final String? churchId;
  final AppPermissions? permissions;
  final CellService? cellService;
  final MemberService? memberService;
  final CellSplitService? splitService;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<SplitCellFromCapacityScreen> createState() =>
      _SplitCellFromCapacityScreenState();
}

class _SplitCellFromCapacityScreenState
    extends State<SplitCellFromCapacityScreen> {
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
  final _leaderEmailController = TextEditingController();
  final _leaderPasswordController = TextEditingController();
  final _leaderConfirmPasswordController = TextEditingController();

  late final CellService _cellService;
  late final MemberService _memberService;
  late final CellSplitService _splitService;

  ChurchCell? _sourceCell;
  List<ChurchMember> _cellMembers = [];
  List<ChurchMember> _helperMembers = [];
  String? _selectedLeaderMemberId;
  final Set<String> _selectedMemberIds = {};
  LeaderGender? _leaderGender;
  GeoLocation? _cellLocation;
  String? _cellDay;
  bool _loading = true;
  String? _loadError;
  bool _isSaving = false;
  bool _leaderAccountRequired = false;
  bool _checkingLeaderAccount = false;
  bool _obscureLeaderPassword = true;
  bool _obscureLeaderConfirmPassword = true;

  static const _cellDayStorageValues = [
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
    _cellService = widget.cellService ?? CellService();
    _memberService = widget.memberService ?? MemberService();
    _splitService = widget.splitService ?? CellSplitService();
    _load();
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
    _leaderEmailController.dispose();
    _leaderPasswordController.dispose();
    _leaderConfirmPasswordController.dispose();
    super.dispose();
  }

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final cell = await _cellService.fetchCellById(widget.sourceCellId);
      if (cell == null) {
        if (!mounted) return;
        setState(() {
          _loadError = context.l10n.cellDiscipleCellMissing;
          _loading = false;
        });
        return;
      }

      final members = await _memberService.fetchMembersInCell(widget.sourceCellId);
      final helpers = _splitService.membersForHelpers(
        helpers: cell.helpers,
        cellMembers: members,
      );
      final leaderGender = await fetchCellLeaderGender(cell);

      if (!mounted) return;
      setState(() {
        _sourceCell = cell;
        _cellMembers = members;
        _helperMembers = helpers;
        _leaderGender = leaderGender;
        _cellDay = cell.cellDay;
        _streetController.text = cell.street ?? '';
        _streetNumberController.text = cell.streetNumber ?? '';
        _neighborhoodController.text = cell.neighborhood ?? '';
        _localityController.text = cell.locality ?? '';
        _stateProvinceController.text = cell.stateProvince ?? 'Buenos Aires';
        _postalCodeController.text = cell.postalCode ?? '';
        _cellLocation = cell.geoLocation;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = context.l10n.splitCellLoadError;
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  ChurchMember? _memberById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final member in _cellMembers) {
      if (member.id == id) return member;
    }
    return null;
  }

  Future<void> _onLeaderHelperSelected(String? memberId) async {
    setState(() {
      _selectedLeaderMemberId = memberId;
      if (memberId != null) {
        _selectedMemberIds.remove(memberId);
        _leaderGender = _memberById(memberId)?.gender ?? _leaderGender;
      }
      _leaderAccountRequired = false;
      _checkingLeaderAccount = memberId != null;
    });

    if (memberId == null) return;

    final member = _memberById(memberId);
    final churchId = widget.churchId ?? _sourceCell?.churchId;
    if (member == null || churchId == null || churchId.isEmpty) {
      if (!mounted) return;
      setState(() => _checkingLeaderAccount = false);
      return;
    }

    try {
      final existing = await _splitService.findExistingLeaderForMember(
        member: member,
        churchId: churchId,
      );
      final needsAccount =
          existing == null || !_splitService.leaderHasAppAccount(existing);
      if (!mounted) return;
      setState(() {
        _leaderAccountRequired = needsAccount;
        _checkingLeaderAccount = false;
        if (!needsAccount) {
          _leaderEmailController.clear();
          _leaderPasswordController.clear();
          _leaderConfirmPasswordController.clear();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _leaderAccountRequired = true;
        _checkingLeaderAccount = false;
      });
    }
  }

  List<ChurchMember> get _transferCandidates {
    final leaderId = _selectedLeaderMemberId;
    return _cellMembers.where((member) {
      final id = member.id;
      if (id == null || id.isEmpty) return false;
      if (leaderId != null && id == leaderId) return false;
      return true;
    }).toList();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final sourceCell = _sourceCell;
    if (sourceCell == null) return;

    final leaderMember = _memberById(_selectedLeaderMemberId);
    if (leaderMember == null) {
      _showMessage(l10n.splitCellLeaderRequired);
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      _showMessage(l10n.splitCellMembersRequired);
      return;
    }

    final membersToTransfer = _selectedMemberIds
        .map(_memberById)
        .whereType<ChurchMember>()
        .toList();

    setState(() => _isSaving = true);
    try {
      await _splitService.splitFromCapacity(
        sourceCell: sourceCell,
        newCell: ChurchCell(
          code: _codeController.text.trim(),
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
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          registeredAt: DateTime.now(),
          registeredBy: widget.registeredBy,
          churchId: widget.churchId ?? sourceCell.churchId,
        ),
        leaderHelperMember: leaderMember,
        membersToTransfer: membersToTransfer,
        registeredBy: widget.registeredBy,
        leaderEmail: _leaderAccountRequired
            ? _leaderEmailController.text.trim()
            : null,
        leaderPassword: _leaderAccountRequired
            ? _leaderPasswordController.text
            : null,
      );

      if (!mounted) return;
      _showMessage(l10n.splitCellSuccess);
      Navigator.of(context).pop(true);
    } on CellSplitLeaderBusyException {
      if (!mounted) return;
      _showMessage(l10n.splitCellLeaderBusy);
    } on CellSplitLeaderAccountRequiredException {
      if (!mounted) return;
      _showMessage(l10n.splitCellLeaderAccountRequired);
    } on CellSplitLeaderBlockedException {
      if (!mounted) return;
      _showMessage(l10n.splitCellLeaderBlocked);
    } on CellSplitGenderMismatchException {
      if (!mounted) return;
      _showMessage(l10n.cellMemberAssignGenderMismatch);
    } on CellSplitCodeDuplicateException {
      if (!mounted) return;
      _showMessage(l10n.cellRegCodeDuplicate);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(AuthService.messageFromFirebaseAuthException(e, l10n));
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

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canRegisterCell,
      deniedMessage: l10n.cellRegDenied,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.splitCellTitle)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _buildForm(l10n),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    final sourceCell = _sourceCell!;
    final cellDayOptions = _cellDayOptions(l10n);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: Text(l10n.splitCellSourceCellLabel),
                  subtitle: Text(sourceCell.displayLabel),
                ),
              ),
              const SizedBox(height: 24),
              FormSectionTitle(l10n.splitCellNewCellSection),
              TextFormField(
                controller: _codeController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.cellRegCode,
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
              const SizedBox(height: 16),
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
                onChanged:
                    _isSaving ? null : (value) => setState(() => _cellDay = value),
                validator: (value) => value == null || value.isEmpty
                    ? l10n.cellRegMeetingDayRequired
                    : null,
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
                requireAddress: true,
                onStreetCoordinatesSelected: (location) {
                  setState(() => _cellLocation = location);
                },
                onAddressCleared: () {
                  setState(() => _cellLocation = null);
                },
              ),
              const SizedBox(height: 24),
              FormSectionTitle(l10n.splitCellSelectLeaderHelper),
              Text(
                l10n.splitCellSelectLeaderHelperHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              if (_helperMembers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.splitCellNoHelpers,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else
                ..._helperMembers.map((member) {
                  final memberId = member.id;
                  if (memberId == null || memberId.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return RadioListTile<String>(
                    value: memberId,
                    groupValue: _selectedLeaderMemberId,
                    onChanged: _isSaving
                        ? null
                        : (value) => _onLeaderHelperSelected(value),
                    title: Text(member.fullName),
                    subtitle: Text(member.phone),
                  );
                }),
              if (_checkingLeaderAccount)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_selectedLeaderMemberId != null &&
                  !_leaderAccountRequired)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.splitCellLeaderAlreadyHasAccount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                )
              else if (_leaderAccountRequired) ...[
                const SizedBox(height: 16),
                FormSectionTitle(l10n.splitCellLeaderAccountSection),
                Text(
                  l10n.splitCellLeaderAccountHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _leaderEmailController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegEmailLabelRequired,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    helperText: l10n.leaderRegEmailLoginHelper,
                  ),
                  validator: (value) {
                    if (!_leaderAccountRequired) return null;
                    if (value == null || value.trim().isEmpty) {
                      return l10n.leaderRegEmailRequired;
                    }
                    if (!value.contains('@')) return l10n.emailInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _leaderPasswordController,
                  obscureText: _obscureLeaderPassword,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureLeaderPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => setState(
                                () => _obscureLeaderPassword =
                                    !_obscureLeaderPassword,
                              ),
                    ),
                  ),
                  validator: (value) {
                    if (!_leaderAccountRequired) return null;
                    if (value == null || value.isEmpty) {
                      return l10n.leaderRegPasswordRequired;
                    }
                    if (value.length < 6) return l10n.passwordMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _leaderConfirmPasswordController,
                  obscureText: _obscureLeaderConfirmPassword,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: l10n.changePasswordConfirm,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureLeaderConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: _isSaving
                          ? null
                          : () => setState(
                                () => _obscureLeaderConfirmPassword =
                                    !_obscureLeaderConfirmPassword,
                              ),
                    ),
                  ),
                  validator: (value) {
                    if (!_leaderAccountRequired) return null;
                    if (value != _leaderPasswordController.text) {
                      return l10n.changePasswordMismatch;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              FormSectionTitle(l10n.splitCellSelectMembers),
              Text(
                l10n.splitCellSelectMembersHint(CellSplitService.maxTransferMembers),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ..._transferCandidates.map((member) {
                final memberId = member.id;
                if (memberId == null || memberId.isEmpty) {
                  return const SizedBox.shrink();
                }
                final genderMismatch = _leaderGender != null &&
                    member.gender != null &&
                    !memberMatchesCellLeaderGender(
                      memberGender: member.gender,
                      leaderGender: _leaderGender,
                    );
                return CheckboxListTile(
                  value: _selectedMemberIds.contains(memberId),
                  onChanged: _isSaving || genderMismatch
                      ? null
                      : (checked) {
                          setState(() {
                            if (checked == true) {
                              if (_selectedMemberIds.length >=
                                  CellSplitService.maxTransferMembers) {
                                _showMessage(
                                  l10n.splitCellMembersMaxReached(
                                    CellSplitService.maxTransferMembers,
                                  ),
                                );
                                return;
                              }
                              _selectedMemberIds.add(memberId);
                            } else {
                              _selectedMemberIds.remove(memberId);
                            }
                          });
                        },
                  title: Text(member.fullName),
                  subtitle: Text(
                    genderMismatch
                        ? l10n.cellMemberAssignGenderMismatch
                        : member.phone,
                  ),
                );
              }),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isSaving || _helperMembers.isEmpty ? null : _onSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.call_split_outlined),
                label: Text(
                  _isSaving ? l10n.memberSaving : l10n.splitCellCreateAction,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
