import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../address/services/geocoding_service.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/models/app_user_role.dart';
import '../../auth/widgets/role_gate.dart';
import '../../auth/utils/password_validator.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../../auth/widgets/assignable_roles_section.dart';
import '../../address/widgets/address_fields_section.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/widgets/form_section_title.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/id_document_type.dart';
import '../models/church_leader.dart';
import '../models/leader_registration_source.dart';
import '../models/church_office.dart';
import '../services/leader_service.dart';

class RegisterLeaderScreen extends StatefulWidget {
  const RegisterLeaderScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.leaderService,
    this.leaderToEdit,
    this.permissions,
  });

  final String registeredBy;
  /// Iglesia del usuario que registra (admin).
  final String? churchId;
  final LeaderService? leaderService;
  final ChurchLeader? leaderToEdit;
  final AppPermissions? permissions;

  bool get isEditing => leaderToEdit != null;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterLeaderScreen> createState() => _RegisterLeaderScreenState();
}

class _RegisterLeaderScreenState extends State<RegisterLeaderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _localityController = TextEditingController();
  final _stateProvinceController = TextEditingController(text: 'Buenos Aires');
  final _postalCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobilePhoneController = TextEditingController();
  final _idDocumentNumberController = TextEditingController();

  late final LeaderService _leaderService;
  final _authService = AuthService();
  final _userProfileService = UserProfileService();
  final _geocodingService = GeocodingService();

  LeaderGender? _gender;
  IdDocumentType? _idDocumentType;
  DateTime? _birthDate;
  ChurchOffice? _churchOffice;
  Set<String> _selectedRoles = {AppUserRole.leader};
  GeoLocation? _leaderLocation;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _loadingRoles = false;

  bool get _isVolunteerRegistrar =>
      _churchOffice == ChurchOffice.voluntario;

  Set<String> get _rolesForVolunteerRegistrar => {AppUserRole.registrar};

  void _syncRolesForChurchOffice() {
    if (_isVolunteerRegistrar) {
      _selectedRoles = _rolesForVolunteerRegistrar;
    }
  }

  bool get _hasValidVolunteerRegistrarRoles =>
      _selectedRoles.contains(AppUserRole.registrar) &&
      _selectedRoles.every((role) => role == AppUserRole.registrar);

  @override
  void initState() {
    super.initState();
    _leaderService = widget.leaderService ?? LeaderService();
    if (widget.leaderToEdit != null) {
      _loadLeader(widget.leaderToEdit!);
      _loadUserRoles(widget.leaderToEdit!);
    }
  }

  Future<void> _loadUserRoles(ChurchLeader leader) async {
    final authUserId = leader.authUserId;
    if (authUserId == null || authUserId.isEmpty) return;

    setState(() => _loadingRoles = true);
    try {
      final doc = await _userProfileService.fetchProfileDoc(authUserId);
      if (doc != null && mounted) {
        final roles = AppUserRole.parseList(doc.data()?['roles']);
        if (roles.isNotEmpty) {
          setState(() {
            _selectedRoles = leader.churchOffice == ChurchOffice.voluntario
                ? {AppUserRole.registrar}
                : AppUserRole.sanitizeForLeaderRegistration(roles).toSet();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loadingRoles = false);
      }
    }
  }

  void _loadLeader(ChurchLeader leader) {
    _lastNameController.text = leader.lastName;
    _firstNameController.text = leader.firstName;
    _streetController.text = leader.street ?? '';
    _streetNumberController.text = leader.streetNumber ?? '';
    _neighborhoodController.text = leader.neighborhood ?? '';
    _localityController.text = leader.locality ?? '';
    _stateProvinceController.text = leader.stateProvince ?? 'Buenos Aires';
    _postalCodeController.text = leader.postalCode ?? '';
    _emailController.text = leader.email ?? '';
    _mobilePhoneController.text = leader.mobilePhone;
    _gender = leader.gender;
    _idDocumentType = leader.idDocumentType;
    _idDocumentNumberController.text = leader.idDocumentNumber ?? '';
    _birthDate = leader.birthDate;
    _churchOffice = leader.churchOffice;
    _leaderLocation = leader.geoLocation;
    if (_churchOffice == ChurchOffice.voluntario) {
      _selectedRoles = {AppUserRole.registrar};
    }
  }

  void _onChurchOfficeChanged(ChurchOffice? value) {
    setState(() {
      _churchOffice = value;
      if (value == ChurchOffice.voluntario) {
        _selectedRoles = _rolesForVolunteerRegistrar;
      } else if (_selectedRoles.length == 1 &&
          _selectedRoles.contains(AppUserRole.registrar)) {
        _selectedRoles = {AppUserRole.leader};
      }
    });
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _neighborhoodController.dispose();
    _localityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobilePhoneController.dispose();
    _idDocumentNumberController.dispose();
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    await _pickDate(
      initial: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      onPicked: (d) => setState(() => _birthDate = d),
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
              onSelected: _isLoading
                  ? null
                  : (v) => setState(() {
                        _idDocumentType = v ? type : null;
                      }),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    final l10n = context.l10n;

    if (_churchOffice == null) {
      _showMessage(l10n.leaderRegSelectChurchOffice);
      return;
    }
    if (_selectedRoles.isEmpty) {
      _showMessage(l10n.leaderRegSelectAtLeastOneRole);
      return;
    }
    _syncRolesForChurchOffice();
    if (_isVolunteerRegistrar && !_hasValidVolunteerRegistrarRoles) {
      _showMessage(l10n.assignableRolesVolunteerOnly);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var location = _leaderLocation;
      if (location == null) {
        final address = _buildFormattedAddress();
        if (address.isNotEmpty) {
          location = await _geocodingService.geocodeAddress(address);
        }
      }

      if (location == null) {
        if (mounted) {
          _showMessage(l10n.memberAddressGeocodeFailed);
        }
        return;
      }

      final email = _emailController.text.trim().toLowerCase();

      if (!widget.isEditing) {
        final credential = await _authService.createLeaderAccount(
          email: email,
          password: _passwordController.text,
        );
        final authUserId = credential.user?.uid;
        if (authUserId == null) {
          throw FirebaseAuthException(
            code: 'unknown',
            message: l10n.authCreateUserFailed,
          );
        }

        final roles =
            AppUserRole.sanitizeForLeaderRegistration(_selectedRoles.toList());

        final leader = ChurchLeader(
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
          email: email,
          authUserId: authUserId,
          latitude: location.latitude,
          longitude: location.longitude,
          mobilePhone: _mobilePhoneController.text.trim(),
          registeredAt: DateTime.now(),
          registeredBy: widget.registeredBy,
          churchId: widget.churchId,
          registrationSource: LeaderRegistrationSource.registerLeader,
          churchOffice: _churchOffice,
          appRoles: roles,
        );

        final leaderId = await _leaderService.addLeaderWithMember(
          leader: leader,
          registeredBy: widget.registeredBy,
        );

        await _userProfileService.setLeaderProfile(
          uid: authUserId,
          email: email,
          leaderId: leaderId,
          roles: roles,
          churchId: widget.churchId,
        );

        if (!mounted) return;
        _showMessage(l10n.leaderRegSuccessWithLogin);
        Navigator.of(context).pop(true);
        return;
      }

      final roles =
          AppUserRole.sanitizeForLeaderRegistration(_selectedRoles.toList());

      final leader = ChurchLeader(
        id: widget.leaderToEdit?.id,
        lastName: _lastNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        street: _streetController.text.trim().isEmpty
            ? null
            : _streetController.text.trim(),
        streetNumber: _streetNumberController.text.trim().isEmpty
            ? null
            : _streetNumberController.text.trim(),
        cellCode: widget.leaderToEdit?.cellCode,
        gender: _gender,
        idDocumentType: _idDocumentType,
        idDocumentNumber: _idDocumentNumberController.text.trim().isEmpty
            ? null
            : _idDocumentNumberController.text.trim(),
        birthDate: _birthDate,
        maritalStatus: widget.leaderToEdit?.maritalStatus,
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
        email: email.isEmpty ? null : email,
        authUserId: widget.leaderToEdit?.authUserId,
        latitude: location.latitude,
        longitude: location.longitude,
        mobilePhone: _mobilePhoneController.text.trim(),
        registeredAt: widget.leaderToEdit?.registeredAt ?? DateTime.now(),
        registeredBy: widget.leaderToEdit?.registeredBy ?? widget.registeredBy,
        churchId: widget.leaderToEdit?.churchId ?? widget.churchId,
        registrationSource:
            widget.leaderToEdit?.registrationSource ??
            LeaderRegistrationSource.registerLeader,
        churchOffice: _churchOffice,
        appRoles: roles,
        photoUrl: widget.leaderToEdit?.photoUrl,
        isBlocked: widget.leaderToEdit?.isBlocked ?? false,
      );

      await _leaderService.updateLeader(leader);

      final authUserId = widget.leaderToEdit?.authUserId;
      if (authUserId != null && authUserId.isNotEmpty) {
        await _userProfileService.updateUserRoles(
          uid: authUserId,
          roles: roles,
        );
        final previousEmail =
            (widget.leaderToEdit?.email ?? '').trim().toLowerCase();
        if (email.isNotEmpty && email != previousEmail) {
          await _userProfileService.updateAuthEmailByAdmin(
            uid: authUserId,
            email: email,
          );
        }
      }

      if (!mounted) return;
      _showMessage(l10n.leaderRegUpdatedSuccess);
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showMessage(AuthService.messageFromFirebaseAuthException(e, context.l10n));
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        _showMessage(
          context.l10n.leaderRegEmailUpdateFailed(e.message ?? e.code),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(LeaderService.messageFromFirestoreException(e, context.l10n));
      }
    } catch (_) {
      if (mounted) {
        _showMessage(context.l10n.memberSaveUnexpectedError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final permissions = widget._permissions;
    return RoleGate(
      permissions: permissions,
      allowed: widget.isEditing
          ? permissions.canManageAll
          : permissions.canRegisterLeader,
      deniedMessage: widget.isEditing
          ? l10n.leaderRegEditDenied
          : l10n.leaderRegRegisterDenied,
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.leaderRegEditTitle : l10n.leaderRegNewTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSectionTitle(l10n.leaderDetailSectionLeadership),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegLastName,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.leaderRegLastNameRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegFirstNames,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.leaderRegFirstNamesRequired : null,
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
                      onSelected: _isLoading
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
                  enabled: !_isLoading,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
                  enabled: !_isLoading,
                  initialSearchText: widget.leaderToEdit?.formattedAddress,
                  onStreetCoordinatesSelected: (location) {
                    setState(() => _leaderLocation = location);
                  },
                  onAddressCleared: () {
                    setState(() => _leaderLocation = null);
                  },
                ),
                FormSectionTitle(l10n.leaderRegSectionChurchOffice),
                DropdownButtonFormField<ChurchOffice>(
                  initialValue: _churchOffice,
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegChurchOffice,
                    prefixIcon: const Icon(Icons.church_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  items: ChurchOffice.values
                      .map(
                        (office) => DropdownMenuItem(
                          value: office,
                          child: Text(office.localizedLabel(l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading ? null : _onChurchOfficeChanged,
                  validator: (value) =>
                      value == null ? l10n.leaderRegSelectChurchOfficeField : null,
                ),
                const SizedBox(height: 24),
                FormSectionTitle(l10n.leaderDetailSectionRoles),
                if (_loadingRoles)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else
                  AssignableRolesSection(
                    selectedRoles: _selectedRoles,
                    enabled: !_isLoading,
                    allowedRoles: _isVolunteerRegistrar
                        ? const [AppUserRole.registrar]
                        : null,
                    lockRegistrarWhenOnly: _isVolunteerRegistrar,
                    onChanged: (roles) => setState(() {
                      if (_isVolunteerRegistrar) {
                        _selectedRoles = _rolesForVolunteerRegistrar;
                      } else {
                        _selectedRoles = roles;
                      }
                    }),
                  ),
                if (widget.isEditing && widget.leaderToEdit?.authUserId == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.leaderRegNoAccessAccountHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 24),
                FormSectionTitle(l10n.leaderDetailSectionCellContact),
                TextFormField(
                  controller: _mobilePhoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.leaderDetailMobile,
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.leaderRegMobileRequired : null,
                ),
                const SizedBox(height: 24),
                FormSectionTitle(l10n.leaderRegSectionAppAccess),
                if (!widget.isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.leaderRegEmailLoginHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: widget.isEditing
                        ? l10n.leaderRegEmailLabel
                        : l10n.leaderRegEmailLabelRequired,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    helperText: widget.isEditing
                        ? (widget.leaderToEdit?.authUserId != null
                            ? l10n.leaderRegEmailAdminEditHelper
                            : l10n.leaderRegEmailLoginHelper)
                        : l10n.leaderRegEmailLoginHelper,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.leaderRegEmailRequired;
                    }
                    if (!v.contains('@')) return l10n.emailInvalid;
                    return null;
                  },
                ),
                if (!widget.isEditing) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return l10n.leaderRegPasswordRequired;
                      }
                      return PasswordValidator.validateRegistration(l10n, v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: l10n.changePasswordConfirm,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return l10n.changePasswordMismatch;
                      }
                      return null;
                    },
                  ),
                ],
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
                        ? l10n.commonSaving
                        : widget.isEditing
                            ? l10n.memberSaveChanges
                            : l10n.leaderRegSubmitButton,
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
