import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../address/services/geocoding_service.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/models/app_user_role.dart';
import '../../auth/widgets/role_gate.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../../auth/widgets/assignable_roles_section.dart';
import '../../address/widgets/address_fields_section.dart';
import '../../core/models/geo_location.dart';
import '../../core/models/leader_gender.dart';
import '../../core/widgets/form_section_title.dart';
import '../models/church_leader.dart';
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
  final _cellCodeController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _localityController = TextEditingController();
  final _stateProvinceController = TextEditingController(text: 'Buenos Aires');
  final _postalCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobilePhoneController = TextEditingController();

  late final LeaderService _leaderService;
  final _authService = AuthService();
  final _userProfileService = UserProfileService();
  final _geocodingService = GeocodingService();

  LeaderGender? _gender;
  ChurchOffice? _churchOffice;
  Set<String> _selectedRoles = {AppUserRole.leader};
  GeoLocation? _leaderLocation;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _loadingRoles = false;

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
            _selectedRoles =
                AppUserRole.sanitizeForLeaderRegistration(roles).toSet();
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
    _cellCodeController.text = leader.cellCode ?? '';
    _neighborhoodController.text = leader.neighborhood ?? '';
    _localityController.text = leader.locality ?? '';
    _stateProvinceController.text = leader.stateProvince ?? 'Buenos Aires';
    _postalCodeController.text = leader.postalCode ?? '';
    _emailController.text = leader.email ?? '';
    _mobilePhoneController.text = leader.mobilePhone;
    _gender = leader.gender;
    _churchOffice = leader.churchOffice;
    _leaderLocation = leader.geoLocation;
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobilePhoneController.dispose();
    super.dispose();
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

    if (_churchOffice == null) {
      _showMessage('Selecciona el cargo en la iglesia');
      return;
    }
    if (_selectedRoles.isEmpty) {
      _showMessage('Selecciona al menos un rol en la app');
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
          _showMessage(
            'No se pudo ubicar la dirección. Selecciónala del autocompletado.',
          );
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
            message: 'No se pudo crear el usuario',
          );
        }

        final leader = ChurchLeader(
          lastName: _lastNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          street: _streetController.text.trim().isEmpty
              ? null
              : _streetController.text.trim(),
          streetNumber: _streetNumberController.text.trim().isEmpty
              ? null
              : _streetNumberController.text.trim(),
          cellCode: _cellCodeController.text.trim().isEmpty
              ? null
              : _cellCodeController.text.trim(),
          gender: _gender,
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
          churchOffice: _churchOffice,
        );

        final leaderId = await _leaderService.addLeader(leader);

        await _userProfileService.setLeaderProfile(
          uid: authUserId,
          email: email,
          leaderId: leaderId,
          roles: _selectedRoles.toList(),
          churchId: widget.churchId,
        );

        if (!mounted) return;
        _showMessage(
          'Líder registrado. Puede ingresar con su correo y contraseña.',
        );
        Navigator.of(context).pop(true);
        return;
      }

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
        cellCode: _cellCodeController.text.trim().isEmpty
            ? null
            : _cellCodeController.text.trim(),
        gender: _gender,
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
        churchOffice: _churchOffice,
      );

      await _leaderService.updateLeader(leader);

      final authUserId = widget.leaderToEdit?.authUserId;
      if (authUserId != null && authUserId.isNotEmpty) {
        await _userProfileService.updateUserRoles(
          uid: authUserId,
          roles: _selectedRoles.toList(),
        );
      }

      if (!mounted) return;
      _showMessage('Líder actualizado correctamente');
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showMessage(AuthService.messageFromFirebaseAuthException(e));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(LeaderService.messageFromFirestoreException(e));
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

  @override
  Widget build(BuildContext context) {
    final permissions = widget._permissions;
    return RoleGate(
      permissions: permissions,
      allowed: widget.isEditing
          ? permissions.canManageAll
          : permissions.canRegisterLeader,
      deniedMessage: widget.isEditing
          ? 'Solo el administrador puede editar líderes.'
          : 'No tienes permiso para registrar líderes.',
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar líder' : 'Nuevo líder'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FormSectionTitle('DATOS DEL LIDERAZGO'),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Apellido *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa el apellido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombres *',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa los nombres' : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Género',
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
                          : (v) => setState(() => _gender = v ? g : null),
                    );
                  }).toList(),
                ),
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
                ),
                const FormSectionTitle('CARGO EN LA IGLESIA'),
                DropdownButtonFormField<ChurchOffice>(
                  initialValue: _churchOffice,
                  decoration: const InputDecoration(
                    labelText: 'Cargo *',
                    prefixIcon: Icon(Icons.church_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: ChurchOffice.values
                      .map(
                        (office) => DropdownMenuItem(
                          value: office,
                          child: Text(office.label),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() => _churchOffice = value),
                  validator: (value) =>
                      value == null ? 'Selecciona el cargo' : null,
                ),
                const SizedBox(height: 24),
                const FormSectionTitle('ROLES EN LA APP'),
                if (_loadingRoles)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else
                  AssignableRolesSection(
                    selectedRoles: _selectedRoles,
                    enabled: !_isLoading,
                    onChanged: (roles) => setState(() => _selectedRoles = roles),
                  ),
                if (widget.isEditing && widget.leaderToEdit?.authUserId == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Sin cuenta de acceso: los roles se aplicarán cuando '
                      'se cree el usuario.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 24),
                const FormSectionTitle('CÉLULA Y CONTACTO'),
                TextFormField(
                  controller: _cellCodeController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Célula',
                    hintText: 'Ej: Ñ10, E4, L4',
                    prefixIcon: Icon(Icons.groups_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa el celular' : null,
                ),
                const SizedBox(height: 24),
                const FormSectionTitle('ACCESO A LA APP'),
                if (!widget.isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'El líder ingresará con su correo como usuario.',
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
                  enabled: !_isLoading && widget.isEditing
                      ? widget.leaderToEdit?.authUserId == null
                      : true,
                  readOnly: widget.isEditing &&
                      widget.leaderToEdit?.authUserId != null,
                  decoration: InputDecoration(
                    labelText: widget.isEditing
                        ? 'Correo (usuario de acceso)'
                        : 'Correo (usuario de acceso) *',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    helperText: widget.isEditing &&
                            widget.leaderToEdit?.authUserId != null
                        ? 'La cuenta ya fue creada; el correo no se puede cambiar aquí'
                        : 'Será el usuario para iniciar sesión',
                  ),
                  validator: (v) {
                    if (widget.isEditing &&
                        widget.leaderToEdit?.authUserId != null) {
                      return null;
                    }
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el correo del líder';
                    }
                    if (!v.contains('@')) return 'Correo no válido';
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
                      labelText: 'Contraseña *',
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
                        return 'Ingresa una contraseña';
                      }
                      if (v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña *',
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
                        return 'Las contraseñas no coinciden';
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
                        ? 'Guardando...'
                        : widget.isEditing
                            ? 'Guardar cambios'
                            : 'Registrar líder',
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
