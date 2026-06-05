import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../address/services/nominatim_service.dart';
import '../../address/widgets/address_autocomplete_field.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/models/geo_location.dart';
import '../../core/widgets/church_location_map_preview.dart';
import '../../core/widgets/church_logo.dart';
import '../../core/widgets/form_section_title.dart';
import '../models/church_profile.dart';
import '../services/church_service.dart';

/// Registro y edición de los datos de la iglesia (nombre, dirección, logo).
class RegisterChurchScreen extends StatefulWidget {
  const RegisterChurchScreen({
    super.key,
    required this.updatedBy,
    required this.permissions,
    this.churchService,
    this.churchId,
    this.createNew = false,
    this.readOnly = false,
  });

  final String updatedBy;
  final AppPermissions permissions;
  final ChurchService? churchService;

  /// Iglesia a editar. Si es null y [createNew] es false, usa [permissions.churchId].
  final String? churchId;

  /// Si es true, crea un documento nuevo en `churches`.
  final bool createNew;

  /// Solo consulta: campos y logo sin edición (p. ej. registrador en Mi cuenta).
  final bool readOnly;

  @override
  State<RegisterChurchScreen> createState() => _RegisterChurchScreenState();
}

class _RegisterChurchScreenState extends State<RegisterChurchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();

  late final ChurchService _churchService;
  final _nominatim = NominatimService();

  bool _loading = true;
  bool _saving = false;
  String? _existingLogoUrl;
  Uint8List? _pickedLogoBytes;
  String? _pickedContentType;
  GeoLocation? _churchLocation;
  bool _addressFromSelection = false;
  String? _loadedAddress;
  GeoLocation? _loadedLocation;
  bool _isBlocked = false;

  String? get _effectiveChurchId {
    if (widget.createNew) return null;
    final id = widget.churchId ?? widget.permissions.churchId;
    if (id != null && id.isNotEmpty) return id;
    return ChurchService.mainChurchId;
  }

  @override
  void initState() {
    super.initState();
    _churchService = widget.churchService ?? ChurchService();
    _addressController.addListener(_onAddressTextChanged);
    _loadChurch();
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressTextChanged);
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressTextChanged() {
    if (_addressFromSelection) {
      _addressFromSelection = false;
      return;
    }
    if (_churchLocation == null) return;
    setState(() => _churchLocation = null);
  }

  Future<void> _loadChurch() async {
    if (widget.createNew) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final church = await _churchService.fetchChurch(_effectiveChurchId);
      if (!mounted) return;
      if (church != null) {
        _nameController.text = church.name;
        _addressController.text = church.address;
        _existingLogoUrl = church.logoUrl;
        _isBlocked = church.isBlocked;
        _loadedAddress = church.address.trim();
        if (church.hasCoordinates) {
          _loadedLocation = GeoLocation(
            latitude: church.latitude!,
            longitude: church.longitude!,
          );
          _churchLocation = _loadedLocation;
          _addressFromSelection = true;
        } else if (church.address.trim().length >= 3) {
          await _geocodeAddressForPreview(church.address);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar los datos de la iglesia.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _geocodeAddressForPreview(String address) async {
    try {
      final results = await _nominatim.searchPlaces(address, limit: 1);
      if (results.isEmpty || !mounted) return;
      final enriched = await _nominatim.enrichPlace(results.first);
      if (!mounted) return;
      setState(() => _churchLocation = enriched.location);
    } catch (_) {}
  }

  void _onPlaceSelected(NominatimPlace place) {
    setState(() {
      _addressFromSelection = true;
      _addressController.text = place.displayName;
      _churchLocation = place.location;
    });
  }

  bool get _isAddressValid {
    if (_churchLocation != null) return true;
    final current = _addressController.text.trim();
    if (_loadedAddress != null &&
        current == _loadedAddress &&
        _loadedLocation != null) {
      return true;
    }
    if (!widget.createNew &&
        _loadedAddress != null &&
        current == _loadedAddress) {
      return true;
    }
    return false;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Busca y selecciona una dirección';
    }
    if (!_isAddressValid) {
      return 'Elige una dirección de la lista para ubicarla en el mapa';
    }
    return null;
  }

  ChurchProfile _buildProfile({String? logoUrl}) {
    final location = _churchLocation ?? _loadedLocation;
    return ChurchProfile(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      logoUrl: logoUrl,
      latitude: location?.latitude,
      longitude: location?.longitude,
      isBlocked: _isBlocked,
      updatedBy: widget.updatedBy,
    );
  }

  Future<void> _pickLogo() async {
    if (_saving) return;
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
        _pickedLogoBytes = bytes;
        _pickedContentType = 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar la imagen: $e')),
      );
    }
  }

  void _clearPickedLogo() {
    setState(() {
      _pickedLogoBytes = null;
      _pickedContentType = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      var logoUrl = _existingLogoUrl;
      var targetChurchId = _effectiveChurchId ?? ChurchService.mainChurchId;

      if (widget.createNew) {
        targetChurchId = await _churchService.addChurch(
          profile: _buildProfile(),
          updatedBy: widget.updatedBy,
        );
      }

      if (_pickedLogoBytes != null) {
        logoUrl = await _churchService.uploadLogo(
          _pickedLogoBytes!,
          churchId: targetChurchId,
          contentType: _pickedContentType,
        );
      }

      final profile = _buildProfile(logoUrl: logoUrl);

      if (!widget.createNew) {
        await _churchService.saveChurch(
          churchId: targetChurchId,
          profile: profile,
          updatedBy: widget.updatedBy,
        );
      } else if (logoUrl != null) {
        await _churchService.saveChurch(
          churchId: targetChurchId,
          profile: profile,
          updatedBy: widget.updatedBy,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.createNew
                ? 'Iglesia registrada'
                : 'Datos de la iglesia guardados',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ChurchService.messageFromException(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildLogoPreview() {
    if (_pickedLogoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _pickedLogoBytes!,
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
      );
    }
    if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _existingLogoUrl!,
          width: 140,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => ChurchLogo(
            size: 140,
            churchId: _effectiveChurchId,
          ),
        ),
      );
    }
    return ChurchLogo(size: 140, churchId: _effectiveChurchId);
  }

  @override
  Widget build(BuildContext context) {
    final allowed = widget.createNew
        ? widget.permissions.canCreateChurch
        : widget.readOnly
            ? widget.permissions.canViewChurchData ||
                widget.permissions.canEditAnyChurch
            : widget.permissions.canEditAnyChurch;

    final title = widget.createNew
        ? 'Nueva iglesia'
        : widget.readOnly
            ? 'Datos de la iglesia'
            : widget.permissions.isSuperAdmin
                ? 'Editar iglesia'
                : 'Datos de la iglesia';

    final lockedByBlock =
        _isBlocked && !widget.permissions.isSuperAdmin && !widget.createNew;
    final editable = !widget.readOnly && !lockedByBlock;

    return RoleGate(
      permissions: widget.permissions,
      allowed: allowed,
      deniedMessage: widget.createNew
          ? 'Solo el super administrador puede crear iglesias.'
          : widget.readOnly
              ? 'No tienes permiso para ver los datos de esta iglesia.'
              : 'No tienes permiso para editar los datos de esta iglesia.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (lockedByBlock)
                          Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.block_outlined,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Esta iglesia está bloqueada. '
                                      'Contacta al super administrador para reactivarla.',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (lockedByBlock) const SizedBox(height: 16),
                        FormSectionTitle(
                          widget.readOnly ? 'LOGO' : 'LOGO (opcional)',
                        ),
                        Center(child: _buildLogoPreview()),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Puedes guardar sin logo; se usará el predeterminado.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed:
                                    _saving || lockedByBlock ? null : _pickLogo,
                                icon: const Icon(Icons.upload_outlined),
                                label: const Text('Subir logo'),
                              ),
                              if (_pickedLogoBytes != null) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _saving ? null : _clearPickedLogo,
                                  child: const Text('Quitar'),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        const FormSectionTitle('INFORMACIÓN'),
                        TextFormField(
                          controller: _nameController,
                          readOnly: widget.readOnly,
                          enabled: editable && !_saving,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: widget.readOnly
                                ? 'Nombre de la iglesia'
                                : 'Nombre de la iglesia *',
                            prefixIcon: const Icon(Icons.church_outlined),
                            border: const OutlineInputBorder(),
                            filled: widget.readOnly,
                          ),
                          validator: editable
                              ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa el nombre';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        if (widget.readOnly)
                          TextFormField(
                            controller: _addressController,
                            readOnly: true,
                            enabled: false,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(),
                              filled: true,
                            ),
                          )
                        else
                          AddressAutocompleteField(
                            controller: _addressController,
                            enabled: editable && !_saving,
                            showInlineMapPreview: false,
                            suggestionsLocked: _churchLocation != null ||
                                (_loadedAddress != null &&
                                    _addressController.text.trim() ==
                                        _loadedAddress &&
                                    _addressController.text.trim().length >= 3),
                            labelText: 'Buscar dirección *',
                            hintText: 'Escribe y elige una sugerencia…',
                            onPlaceSelected: _onPlaceSelected,
                            validator: _validateAddress,
                          ),
                        if (_churchLocation != null) ...[
                          const SizedBox(height: 12),
                          ChurchLocationMapPreview(location: _churchLocation!),
                        ],
                        if (editable) ...[
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_saving ? 'Guardando…' : 'Guardar'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
