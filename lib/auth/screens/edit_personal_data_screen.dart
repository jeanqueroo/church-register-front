import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

/// Formulario solo para datos personales (sin contraseña).
class EditPersonalDataScreen extends StatefulWidget {
  const EditPersonalDataScreen({
    super.key,
    required this.session,
    this.userProfileService,
  });

  final UserSession session;
  final UserProfileService? userProfileService;

  @override
  State<EditPersonalDataScreen> createState() => _EditPersonalDataScreenState();
}

class _EditPersonalDataScreenState extends State<EditPersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final UserProfileService _profileService;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profileService = widget.userProfileService ?? UserProfileService();
    final profile = widget.session.profile;
    _fullNameController = TextEditingController(text: profile.fullName ?? '');
    _emailController = TextEditingController(
      text: profile.email ?? widget.session.email,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
      await _profileService.updatePersonalData(
        uid: widget.session.uid,
        fullName: _fullNameController.text,
        email: widget.session.email,
      );
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
        return 'Error al guardar. Intenta de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabels = widget.session.profile.permissions.roleLabels;

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
              'Actualiza tu nombre. Para cambiar la contraseña usa '
              '«Cambiar contraseña» en Mi cuenta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu nombre completo';
                }
                return null;
              },
            ),
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
