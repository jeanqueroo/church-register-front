import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../address/services/geocoding_service.dart';
import '../../address/widgets/address_fields_section.dart';
import '../../core/models/geo_location.dart';
import '../../core/widgets/form_section_title.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
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
  late final TextEditingController _mobilePhoneController;
  late final TextEditingController _emailController;
  late final UserProfileService _profileService;
  late final LeaderService _leaderService;
  final _geocodingService = GeocodingService();

  bool _isLoading = false;
  bool _loadingLeader = false;
  ChurchLeader? _leader;
  GeoLocation? _leaderLocation;

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

  /// Nombre, dirección y teléfono (no solo nombre como el admin de iglesia).
  bool get _editsFullLeaderFields =>
      _isLeaderAccount ||
      widget.session.profile.permissions.isRegistrar ||
      widget.session.profile.permissions.isSupervisor;

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
    _mobilePhoneController = TextEditingController();
    _emailController = TextEditingController(
      text: profile.email ?? widget.session.email,
    );
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
    _mobilePhoneController.text = leader.mobilePhone;
    _leaderLocation = leader.geoLocation;
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
    _mobilePhoneController.dispose();
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
      if (_usesLeaderRecord) {
        final leader = _leader;
        var leaderId = leader?.id ?? widget.session.profile.leaderId;

        if (_editsFullLeaderFields) {
          if (leader == null || leaderId == null || leaderId.isEmpty) {
            _showMessage('No se encontró tu ficha de datos.');
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
            _showMessage(
              'No se pudo ubicar la dirección. Selecciónala del autocompletado.',
            );
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
              churchOffice: leader.churchOffice,
            ),
          );
        } else {
          if (leaderId == null || leaderId.isEmpty) {
            leaderId = await _leaderService.addLeader(
              ChurchLeader(
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                email: widget.session.email,
                authUserId: widget.session.uid,
                mobilePhone: '-',
                registeredAt: DateTime.now(),
                registeredBy: widget.session.email,
              ),
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
              ),
            );
          }
        }
      } else {
        _showMessage('No se encontró tu ficha de datos.');
        return;
      }
      if (!mounted) return;
      _showMessage('Datos personales actualizados');
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(_messageFromFirestore(e));
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudieron guardar los datos.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFromFirestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para actualizar tu perfil.';
      default:
        return LeaderService.messageFromFirestoreException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabels = widget.session.profile.permissions.roleLabels;

    if (_usesLeaderRecord && _loadingLeader) {
      return Scaffold(
        appBar: AppBar(title: const Text('Datos personales')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_usesLeaderRecord && _leader == null && _editsFullLeaderFields) {
      return Scaffold(
        appBar: AppBar(title: const Text('Datos personales')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No se encontró tu ficha de datos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadLeader,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos personales'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _editsFullLeaderFields
                  ? 'Actualiza tu nombre, dirección y teléfono. '
                      'Para cambiar la contraseña usa «Cambiar contraseña» en Mi cuenta.'
                  : 'Actualiza tu nombre en tu ficha. Para cambiar la contraseña usa '
                      '«Cambiar contraseña» en Mi cuenta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (_usesLeaderRecord) ...[
              if (!_editsFullLeaderFields) const FormSectionTitle('NOMBRE'),
              if (!_editsFullLeaderFields) ...[
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
            if (_editsFullLeaderFields) ...[
              const FormSectionTitle('NOMBRE'),
              TextFormField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Apellido *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu apellido';
                  }
                  return null;
                },
              ),
              AddressFieldsSection(
                streetController: _streetController,
                streetNumberController: _streetNumberController,
                neighborhoodController: _neighborhoodController,
                localityController: _localityController,
                stateProvinceController: _stateProvinceController,
                postalCodeController: _postalCodeController,
                enabled: !_isLoading,
                initialSearchText: _leader?.formattedAddress,
                onStreetCoordinatesSelected: (location) {
                  setState(() => _leaderLocation = location);
                },
              ),
              const FormSectionTitle('CONTACTO'),
              TextFormField(
                controller: _mobilePhoneController,
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Celular / Móvil *',
                  hintText: 'Ej: 15-1234-5678',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu número de teléfono';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Correo de inicio de sesión',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                helperText: 'El correo de acceso no se modifica desde aquí',
              ),
            ),
            if (roleLabels.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Roles en el sistema',
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
              const SizedBox(height: 4),
              Text(
                'Los roles solo puede modificarlos un administrador.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                  : const Text('Guardar datos'),
            ),
          ],
        ),
      ),
    );
  }
}
