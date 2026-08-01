import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../address/services/geocoding_service.dart';
import '../../address/widgets/address_fields_section.dart';
import '../../core/models/geo_location.dart';
import '../../core/widgets/form_section_title.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/models/leader_registration_source.dart';
import '../../leaders/services/leader_service.dart';
import '../../members/models/id_document_type.dart';
import '../../members/models/marital_status.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../utils/person_name.dart';

/// Formulario solo para datos personales (sin contraseña).
class EditPersonalDataScreen extends StatefulWidget {
  const EditPersonalDataScreen({
    super.key,
    required this.session,
    this.userProfileService,
    this.leaderService,
  });

  final UserSession session;
  final UserProfileService? userProfileService;
  final LeaderService? leaderService;

  @override
  State<EditPersonalDataScreen> createState() => _EditPersonalDataScreenState();
}

class _EditPersonalDataScreenState extends State<EditPersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _streetController;
  late final TextEditingController _streetNumberController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _localityController;
  late final TextEditingController _stateProvinceController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _idDocumentNumberController;
  late final TextEditingController _mobilePhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _occupationController;
  late final UserProfileService _profileService;
  late final LeaderService _leaderService;
  final _geocodingService = GeocodingService();
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _loadingLeader = false;
  ChurchLeader? _leader;
  GeoLocation? _leaderLocation;
  IdDocumentType? _idDocumentType;
  DateTime? _birthDate;
  MaritalStatus? _maritalStatus;
  String? _existingPhotoUrl;
  Uint8List? _pickedPhotoBytes;
  bool _removePhoto = false;

  bool get _isLeaderAccount => widget.session.isLeaderAccount;

  bool get _hasLinkedLeaderId {
    final id = widget.session.profile.leaderId;
    return id != null && id.isNotEmpty;
  }

  /// Cuenta vinculada a ficha en `leaders` (líder, registrador, supervisor, admin).
  bool get _usesLeaderRecord =>
      _isLeaderAccount ||
      widget.session.profile.permissions.isAdmin ||
      _hasLinkedLeaderId;

  /// Nombre, dirección, documento y teléfono.
  bool get _editsFullLeaderFields =>
      _isLeaderAccount ||
      widget.session.profile.permissions.isRegistrar ||
      widget.session.profile.permissions.isSupervisor ||
      (widget.session.profile.permissions.isAdmin && _hasLinkedLeaderId);

  @override
  void initState() {
    super.initState();
    _profileService = widget.userProfileService ?? UserProfileService();
    _leaderService = widget.leaderService ?? LeaderService();
    final profile = widget.session.profile;
    _fullNameController = TextEditingController(
      text: widget.session.resolvedDisplayName,
    );
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _streetController = TextEditingController();
    _streetNumberController = TextEditingController();
    _neighborhoodController = TextEditingController();
    _localityController = TextEditingController();
    _stateProvinceController = TextEditingController(text: 'Buenos Aires');
    _postalCodeController = TextEditingController();
    _idDocumentNumberController = TextEditingController();
    _mobilePhoneController = TextEditingController();
    _occupationController = TextEditingController();
    _emailController = TextEditingController(
      text: profile.email ?? widget.session.email,
    );
    _existingPhotoUrl = profile.photoUrl;
    if (_usesLeaderRecord) {
      _loadLeader();
    }
  }

  Future<void> _loadLeader() async {
    setState(() => _loadingLeader = true);
    try {
      final profileLeaderId = widget.session.profile.leaderId;
      ChurchLeader? leader;
      if (profileLeaderId != null && profileLeaderId.isNotEmpty) {
        leader = await _leaderService.fetchLeaderById(profileLeaderId);
      }
      leader ??=
          await _leaderService.fetchLeaderByAuthUserId(widget.session.uid);

      if (!mounted) return;
      setState(() {
        _leader = leader;
        if (leader != null) {
          _populateFromLeader(leader);
        } else if (!_isLeaderAccount) {
          final names = PersonName.split(widget.session.resolvedDisplayName);
          _firstNameController.text = names.firstName;
          _lastNameController.text = names.lastName;
        }
        _loadingLeader = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingLeader = false);
      }
    }
  }

  void _populateFromLeader(ChurchLeader leader) {
    _firstNameController.text = leader.firstName;
    _lastNameController.text = leader.lastName;
    _streetController.text = leader.street ?? '';
    _streetNumberController.text = leader.streetNumber ?? '';
    _neighborhoodController.text = leader.neighborhood ?? '';
    _localityController.text = leader.locality ?? '';
    _stateProvinceController.text = leader.stateProvince ?? 'Buenos Aires';
    _postalCodeController.text = leader.postalCode ?? '';
    _idDocumentType = leader.idDocumentType;
    _idDocumentNumberController.text = leader.idDocumentNumber ?? '';
    _birthDate = leader.birthDate;
    _maritalStatus = leader.maritalStatus;
    _occupationController.text = leader.occupation ?? '';
    _mobilePhoneController.text = leader.mobilePhone;
    _leaderLocation = leader.geoLocation;
    final leaderPhoto = leader.photoUrl?.trim();
    if (leaderPhoto != null && leaderPhoto.isNotEmpty) {
      _existingPhotoUrl ??= leaderPhoto;
    }
  }

  Future<void> _pickPhoto() async {
    if (_isLoading) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedPhotoBytes = bytes;
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(context.l10n.editPersonalDataImageError('$e'));
    }
  }

  void _clearPickedPhoto() {
    setState(() {
      if (_pickedPhotoBytes != null) {
        _pickedPhotoBytes = null;
        return;
      }
      _removePhoto = true;
      _existingPhotoUrl = null;
    });
  }

  String? get _effectivePhotoUrl {
    if (_removePhoto) return null;
    return _existingPhotoUrl;
  }

  Future<String?> _resolvePhotoUrlForSave() async {
    if (_pickedPhotoBytes != null) {
      return _profileService.uploadProfilePhoto(
        _pickedPhotoBytes!,
        uid: widget.session.uid,
      );
    }
    if (_removePhoto) return null;
    final existing = _existingPhotoUrl?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    return null;
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _neighborhoodController.dispose();
    _localityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _idDocumentNumberController.dispose();
    _mobilePhoneController.dispose();
    _occupationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final photoUrl = await _resolvePhotoUrlForSave();
      await _profileService.updatePhotoUrl(
        uid: widget.session.uid,
        photoUrl: photoUrl,
      );

      if (_usesLeaderRecord) {
        final leader = _leader;
        var leaderId = leader?.id ?? widget.session.profile.leaderId;

        if (_editsFullLeaderFields) {
          if (leader == null || leaderId == null || leaderId.isEmpty) {
            if (!mounted) return;
            _showMessage(context.l10n.leaderRecordNotFound);
            return;
          }

          var location = _leaderLocation;
          if (location == null) {
            final address = _buildFormattedAddress();
            if (address.isNotEmpty) {
              location = await _geocodingService.geocodeAddress(address);
            }
          }

          if (location == null) {
            if (!mounted) return;
            _showMessage(context.l10n.memberAddressGeocodeFailed);
            return;
          }

          await _leaderService.updateLeader(
            ChurchLeader(
              id: leaderId,
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              street: _streetController.text.trim().isEmpty
                  ? null
                  : _streetController.text.trim(),
              streetNumber: _streetNumberController.text.trim().isEmpty
                  ? null
                  : _streetNumberController.text.trim(),
              cellCode: leader.cellCode,
              gender: leader.gender,
              idDocumentType: _idDocumentType,
              idDocumentNumber: _idDocumentNumberController.text.trim().isEmpty
                  ? null
                  : _idDocumentNumberController.text.trim(),
              birthDate: _birthDate,
              maritalStatus: _maritalStatus,
              occupation: _occupationController.text.trim().isEmpty
                  ? null
                  : _occupationController.text.trim(),
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
              email: leader.email,
              authUserId: leader.authUserId ?? widget.session.uid,
              latitude: location.latitude,
              longitude: location.longitude,
              mobilePhone: _mobilePhoneController.text.trim(),
              registeredAt: leader.registeredAt,
              registeredBy: leader.registeredBy,
              churchId: leader.churchId,
              registrationSource: leader.registrationSource,
              churchOffice: leader.churchOffice,
              photoUrl: photoUrl,
              isBlocked: leader.isBlocked,
            ),
          );
          await _leaderService.updateLeaderPhotoUrl(
            leaderId: leaderId,
            photoUrl: photoUrl,
          );
        } else {
          if (leaderId == null || leaderId.isEmpty) {
            leaderId = await _leaderService.addLeaderWithMember(
              leader: ChurchLeader(
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                email: widget.session.email,
                authUserId: widget.session.uid,
                mobilePhone: '-',
                registeredAt: DateTime.now(),
                registeredBy: widget.session.email,
                churchId: widget.session.profile.churchId,
                registrationSource: LeaderRegistrationSource.registerLeader,
                photoUrl: photoUrl,
              ),
              registeredBy: widget.session.email,
            );
            await _profileService.updateAdminUser(
              uid: widget.session.uid,
              churchId: widget.session.profile.churchId ?? '',
              leaderId: leaderId,
            );
          } else {
            await _leaderService.updateLeader(
              ChurchLeader(
                id: leaderId,
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                email: leader?.email ?? widget.session.email,
                authUserId: leader?.authUserId ?? widget.session.uid,
                mobilePhone: leader?.mobilePhone ?? '-',
                registeredAt: leader?.registeredAt ?? DateTime.now(),
                registeredBy: leader?.registeredBy ?? widget.session.email,
                churchId: leader?.churchId ?? widget.session.profile.churchId,
                registrationSource: leader?.registrationSource ??
                    LeaderRegistrationSource.registerLeader,
                photoUrl: photoUrl ?? leader?.photoUrl,
                isBlocked: leader?.isBlocked ?? false,
              ),
            );
            await _leaderService.updateLeaderPhotoUrl(
              leaderId: leaderId,
              photoUrl: photoUrl,
            );
          }
        }
      }
      if (!mounted) return;
      _showMessage(context.l10n.editPersonalDataSaved);
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          'EditPersonalData save error: [${e.plugin}] ${e.code} — ${e.message}',
        );
      }
      _showMessage(UserProfileService.messageFromException(e, context.l10n));
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('EditPersonalData save error: $e');
      }
      _showMessage(UserProfileService.messageFromException(e, context.l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPhotoPreview() {
    final existing = _effectivePhotoUrl;
    final Widget child;
    if (_pickedPhotoBytes != null) {
      child = Image.memory(
        _pickedPhotoBytes!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (existing != null && existing.isNotEmpty) {
      child = Image.network(
        existing,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoPlaceholder(),
      );
    } else {
      child = _photoPlaceholder();
    }

    return ClipOval(
      child: SizedBox(
        width: 120,
        height: 120,
        child: child,
      ),
    );
  }

  Widget _photoPlaceholder() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_outline,
        size: 56,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roleLabels = widget.session.profile.permissions.roleLabelsFor(l10n);

    if (_usesLeaderRecord && _loadingLeader) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editPersonalDataTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_usesLeaderRecord && _leader == null && _editsFullLeaderFields) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editPersonalDataTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.leaderRecordNotFound,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadLeader,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editPersonalDataTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _editsFullLeaderFields
                  ? l10n.personalDataSubtitleFull
                  : l10n.personalDataSubtitleName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FormSectionTitle(l10n.editPersonalDataPhoto),
            Center(child: _buildPhotoPreview()),
            const SizedBox(height: 8),
            Text(
              l10n.editPersonalDataPhotoHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _pickPhoto,
                  icon: const Icon(Icons.upload_outlined),
                  label: Text(
                    _pickedPhotoBytes != null ||
                            (_effectivePhotoUrl != null &&
                                _effectivePhotoUrl!.isNotEmpty)
                        ? l10n.editPersonalDataChangePhoto
                        : l10n.editPersonalDataUploadPhoto,
                  ),
                ),
                if (_pickedPhotoBytes != null ||
                    (_effectivePhotoUrl != null &&
                        _effectivePhotoUrl!.isNotEmpty)) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _clearPickedPhoto,
                    child: Text(l10n.editPersonalDataRemovePhoto),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            if (_usesLeaderRecord) ...[
              if (!_editsFullLeaderFields) FormSectionTitle(l10n.editPersonalDataSectionName),
              if (!_editsFullLeaderFields) ...[
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.memberFirstName,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.memberFirstNameRequired;
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.memberLastNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
            if (_editsFullLeaderFields) ...[
              FormSectionTitle(l10n.editPersonalDataSectionName),
              TextFormField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: l10n.memberFirstName,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.memberFirstNameRequired;
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.memberLastNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FormSectionTitle(l10n.memberDetailSectionAddress),
              AddressFieldsSection(
                streetController: _streetController,
                streetNumberController: _streetNumberController,
                neighborhoodController: _neighborhoodController,
                localityController: _localityController,
                stateProvinceController: _stateProvinceController,
                postalCodeController: _postalCodeController,
                enabled: !_isLoading,
                showSectionTitle: false,
                initialSearchText: _leader?.formattedAddress,
                onStreetCoordinatesSelected: (location) {
                  setState(() => _leaderLocation = location);
                },
                onAddressCleared: () {
                  setState(() => _leaderLocation = null);
                },
              ),
              const SizedBox(height: 8),
              FormSectionTitle(l10n.memberIdDocumentType),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _idDocumentNumberController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: l10n.memberIdDocumentNumber,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isLoading ? null : _pickBirthDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.leaderRegBirthDate,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                  ),
                  child: Text(
                    _birthDate != null
                        ? _formatDate(_birthDate!)
                        : l10n.memberSelectDate,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (_birthDate != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _birthDate = null),
                    child: Text(l10n.memberClearDate),
                  ),
                ),
              ],
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
              TextFormField(
                controller: _occupationController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: l10n.memberDetailOccupation,
                  prefixIcon: const Icon(Icons.work_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.memberDetailMaritalStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MaritalStatus.values.map((status) {
                  return FilterChip(
                    label: Text(status.localizedLabel(l10n)),
                    selected: _maritalStatus == status,
                    onSelected: _isLoading
                        ? null
                        : (selected) => setState(() {
                              _maritalStatus = selected ? status : null;
                            }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FormSectionTitle(l10n.editPersonalDataSectionContact),
              TextFormField(
                controller: _mobilePhoneController,
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: '${l10n.leaderDetailMobile} *',
                  hintText: 'Ej: 15-1234-5678',
                  prefixIcon: const Icon(Icons.phone_android_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.memberPhoneRequired;
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            if (roleLabels.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.editPersonalDataRoles,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: roleLabels
                    .map((label) => Chip(label: Text(label)))
                    .toList(),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _onSave,
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
