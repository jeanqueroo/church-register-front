import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../church/models/church_record.dart';
import '../../church/screens/register_church_screen.dart';
import '../../church/services/church_service.dart';
import '../../church/widgets/church_search_field.dart';
import '../../core/widgets/form_section_title.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
import '../models/admin_user_record.dart';
import '../models/app_permissions.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/role_gate.dart';

/// Registro y edición de administrador de iglesia con asignación de sede.
class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({
    super.key,
    required this.registeredBy,
    required this.permissions,
    this.authService,
    this.userProfileService,
    this.churchService,
    this.leaderService,
    this.adminToEdit,
  });

  final String registeredBy;
  final AppPermissions permissions;
  final AuthService? authService;
  final UserProfileService? userProfileService;
  final ChurchService? churchService;
  final LeaderService? leaderService;
  final AdminUserRecord? adminToEdit;

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;
  late final UserProfileService _userProfileService;
  late final ChurchService _churchService;
  late final LeaderService _leaderService;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _saving = false;
  ChurchRecord? _selectedChurch;
  bool _initialChurchSynced = false;
  List<ChurchRecord> _churches = [];
  bool _churchesLoading = true;
  StreamSubscription<List<ChurchRecord>>? _churchesSubscription;

  bool get _isEdit => widget.adminToEdit != null;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _userProfileService = widget.userProfileService ?? UserProfileService();
    _churchService = widget.churchService ?? ChurchService();
    _leaderService = widget.leaderService ?? LeaderService();

    _churchesSubscription = _churchService.watchChurches().listen(
      (allChurches) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _churches = _churchesForPicker(allChurches);
            _churchesLoading = false;
          });
          _syncInitialChurchIfNeeded(allChurches);
        });
      },
      onError: (_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _churchesLoading = false);
        });
      },
    );

    final admin = widget.adminToEdit;
    if (admin != null) {
      _firstNameController.text = admin.firstName;
      _lastNameController.text = admin.lastName;
      if (_firstNameController.text.isEmpty &&
          _lastNameController.text.isEmpty &&
          admin.legacyFullName.isNotEmpty) {
        final parts = admin.legacyFullName.trim().split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          _firstNameController.text = parts.first;
          if (parts.length > 1) {
            _lastNameController.text = parts.sublist(1).join(' ');
          }
        }
      }
      _emailController.text = admin.email;
    }
  }

  List<ChurchRecord> _churchesForPicker(List<ChurchRecord> all) {
    final active = all.where((c) => !c.isBlocked).toList();
    final churchId = widget.adminToEdit?.churchId;
    if (churchId == null || churchId.isEmpty) return active;
    if (active.any((c) => c.id == churchId)) return active;
    final current = all.where((c) => c.id == churchId);
    return [...active, ...current];
  }

  void _syncInitialChurchIfNeeded(List<ChurchRecord> churches) {
    if (_initialChurchSynced || !_isEdit) return;
    _initialChurchSynced = true;

    final churchId = widget.adminToEdit?.churchId;
    if (churchId == null || churchId.isEmpty) return;

    final match = churches.where((c) => c.id == churchId);
    if (match.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedChurch = match.first);
    });
  }

  @override
  void dispose() {
    _churchesSubscription?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildChurchPicker() {
    if (_churchesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_churches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'No hay iglesias activas. Crea una o desbloquea una existente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _saving ? null : _openCreateChurch,
                icon: const Icon(Icons.add),
                label: const Text('Crear iglesia'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChurchSearchField(
          key: ValueKey('admin-church-${_selectedChurch?.id ?? 'none'}'),
          churches: _churches,
          selectedChurch: _selectedChurch,
          enabled: !_saving,
          onChurchSelected: (church) => setState(() => _selectedChurch = church),
          validator: (church) =>
              church == null ? 'Selecciona una iglesia' : null,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _saving ? null : _openCreateChurch,
            icon: const Icon(Icons.add),
            label: const Text('Nueva iglesia'),
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateChurch() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterChurchScreen(
          updatedBy: widget.registeredBy,
          permissions: widget.permissions,
          churchService: _churchService,
          createNew: true,
        ),
      ),
    );
    if (created == true && mounted) {
      _showMessage('Iglesia creada. Selecciónala en la lista.');
    }
  }

  ChurchLeader _buildLeaderRecord({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String? leaderId,
    ChurchLeader? existing,
  }) {
    return ChurchLeader(
      id: leaderId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      authUserId: uid,
      mobilePhone: existing?.mobilePhone ?? '-',
      registeredAt: existing?.registeredAt ?? DateTime.now(),
      registeredBy: existing?.registeredBy ?? widget.registeredBy,
      street: existing?.street,
      streetNumber: existing?.streetNumber,
      cellCode: existing?.cellCode,
      gender: existing?.gender,
      neighborhood: existing?.neighborhood,
      locality: existing?.locality,
      stateProvince: existing?.stateProvince,
      postalCode: existing?.postalCode,
      latitude: existing?.latitude,
      longitude: existing?.longitude,
    );
  }

  Future<String> _ensureLeaderId({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String? existingLeaderId,
  }) async {
    if (existingLeaderId != null && existingLeaderId.isNotEmpty) {
      return existingLeaderId;
    }

    final byAuth = await _leaderService.fetchLeaderByAuthUserId(uid);
    if (byAuth?.id != null && byAuth!.id!.isNotEmpty) {
      return byAuth.id!;
    }

    return _leaderService.addLeader(
      _buildLeaderRecord(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChurch == null) {
      _showMessage('Selecciona la iglesia para este administrador.');
      return;
    }

    setState(() => _saving = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      if (_isEdit) {
        final admin = widget.adminToEdit!;
        ChurchLeader? existing;
        final leaderId = admin.leaderId;
        if (leaderId != null && leaderId.isNotEmpty) {
          existing = await _leaderService.fetchLeaderById(leaderId);
        }
        existing ??= await _leaderService.fetchLeaderByAuthUserId(admin.uid);

        final resolvedLeaderId = await _ensureLeaderId(
          uid: admin.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          existingLeaderId: existing?.id ?? admin.leaderId,
        );

        await _leaderService.updateLeader(
          _buildLeaderRecord(
            uid: admin.uid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            leaderId: resolvedLeaderId,
            existing: existing,
          ),
        );

        await _userProfileService.updateAdminUser(
          uid: admin.uid,
          churchId: _selectedChurch!.id,
          leaderId: resolvedLeaderId,
        );
        if (!mounted) return;
        _showMessage('Administrador actualizado');
      } else {
        final credential = await _authService.createLeaderAccount(
          email: email,
          password: _passwordController.text,
        );
        final uid = credential.user?.uid;
        if (uid == null) {
          throw FirebaseAuthException(
            code: 'unknown',
            message: 'No se pudo crear el usuario',
          );
        }

        final leaderId = await _leaderService.addLeader(
          _buildLeaderRecord(
            uid: uid,
            email: email,
            firstName: firstName,
            lastName: lastName,
          ),
        );

        await _userProfileService.setAdminProfile(
          uid: uid,
          email: email,
          churchId: _selectedChurch!.id,
          leaderId: leaderId,
        );
        if (!mounted) return;
        _showMessage('Administrador registrado correctamente');
      }

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(AuthService.messageFromFirebaseAuthException(e));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(e.message ?? 'Error al guardar el perfil.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error al registrar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _isEdit
        ? widget.permissions.canEditAdmin
        : widget.permissions.canRegisterAdmin;

    return RoleGate(
      permissions: widget.permissions,
      allowed: allowed,
      deniedMessage: _isEdit
          ? 'Solo el super administrador puede editar administradores.'
          : 'Solo el super administrador puede registrar administradores de iglesia.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Editar administrador' : 'Nuevo administrador'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormSectionTitle('CUENTA'),
                  TextFormField(
                    controller: _firstNameController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
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
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
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
                    controller: _emailController,
                    enabled: !_saving && !_isEdit,
                    readOnly: _isEdit,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico *',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      helperText: _isEdit
                          ? 'El correo de inicio de sesión no se puede cambiar desde aquí.'
                          : null,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el correo';
                      }
                      if (!v.contains('@')) return 'Correo no válido';
                      return null;
                    },
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_saving,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa la contraseña';
                        if (v.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !_saving,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () =>
                                _obscureConfirmPassword = !_obscureConfirmPassword,
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
                  const SizedBox(height: 24),
                  const FormSectionTitle('IGLESIA ASIGNADA'),
                  Text(
                    'Este administrador solo gestionará la iglesia seleccionada.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildChurchPicker(),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _saving ? null : _onSave,
                    icon: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_isEdit ? Icons.save_outlined : Icons.person_add_outlined),
                    label: Text(
                      _saving
                          ? 'Guardando…'
                          : _isEdit
                              ? 'Guardar cambios'
                              : 'Registrar administrador',
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
