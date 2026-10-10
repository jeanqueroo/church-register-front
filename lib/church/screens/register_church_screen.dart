import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../address/models/address_place.dart';
import '../../address/services/google_places_service.dart';
import '../../address/widgets/address_autocomplete_field.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
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
  final _aliasController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();

  late final ChurchService _churchService;
  final _placesService = GooglePlacesService();

  bool _loading = true;
  bool _saving = false;
  String? _existingLogoUrl;
  Uint8List? _pickedLogoBytes;
  String? _pickedContentType;
  String? _existingOfferingQrUrl;
  Uint8List? _pickedOfferingQrBytes;
  String? _pickedOfferingQrContentType;
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
    _aliasController.dispose();
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
        _aliasController.text = church.alias ?? '';
        _addressController.text = church.address;
        _existingLogoUrl = church.logoUrl;
        _existingOfferingQrUrl = church.offeringQrUrl;
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
          SnackBar(content: Text(context.l10n.churchRegLoadError)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _geocodeAddressForPreview(String address) async {
    try {
      final results = await _placesService.searchPlaces(address, limit: 1);
      if (results.isEmpty || !mounted) return;
      final enriched = await _placesService.enrichPlace(results.first);
      if (!mounted) return;
      setState(() => _churchLocation = enriched.location);
    } catch (_) {}
  }

  void _onPlaceSelected(AddressPlace place) {
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
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) {
      return l10n.addressSearchAndSelect;
    }
    if (!_isAddressValid) {
      return l10n.churchRegPickAddress;
    }
    return null;
  }

  ChurchProfile _buildProfile({String? logoUrl, String? offeringQrUrl}) {
    final location = _churchLocation ?? _loadedLocation;
    return ChurchProfile(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      logoUrl: logoUrl,
      offeringQrUrl: offeringQrUrl,
      alias: _aliasController.text.trim().isEmpty
          ? null
          : _aliasController.text.trim(),
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
        SnackBar(content: Text(context.l10n.churchRegImageError('$e'))),
      );
    }
  }

  void _clearPickedLogo() {
    setState(() {
      _pickedLogoBytes = null;
      _pickedContentType = null;
    });
  }

  Future<void> _pickOfferingQr() async {
    if (_saving) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedOfferingQrBytes = bytes;
        _pickedOfferingQrContentType = 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.churchRegImageError('$e'))),
      );
    }
  }

  void _clearPickedOfferingQr() {
    setState(() {
      _pickedOfferingQrBytes = null;
      _pickedOfferingQrContentType = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      var logoUrl = _existingLogoUrl;
      var offeringQrUrl = _existingOfferingQrUrl;
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

      if (_pickedOfferingQrBytes != null) {
        offeringQrUrl = await _churchService.uploadOfferingQr(
          _pickedOfferingQrBytes!,
          churchId: targetChurchId,
          contentType: _pickedOfferingQrContentType,
        );
      }

      final profile = _buildProfile(
        logoUrl: logoUrl,
        offeringQrUrl: offeringQrUrl,
      );

      if (!widget.createNew) {
        await _churchService.saveChurch(
          churchId: targetChurchId,
          profile: profile,
          updatedBy: widget.updatedBy,
        );
      } else if (logoUrl != null || offeringQrUrl != null) {
        await _churchService.saveChurch(
          churchId: targetChurchId,
          profile: profile,
          updatedBy: widget.updatedBy,
        );
      }

      if (!mounted) return;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.createNew ? l10n.churchRegSaved : l10n.churchRegUpdated,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ChurchService.messageFromException(e, context.l10n))),
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

  Widget _buildOfferingQrPreview() {
    if (_pickedOfferingQrBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _pickedOfferingQrBytes!,
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      );
    }
    if (_existingOfferingQrUrl != null && _existingOfferingQrUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _existingOfferingQrUrl!,
          width: 180,
          height: 180,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _offeringQrPlaceholder(),
        ),
      );
    }
    return _offeringQrPlaceholder();
  }

  Widget _offeringQrPlaceholder() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.qr_code_2_outlined,
        size: 72,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowed = widget.createNew
        ? widget.permissions.canCreateChurch
        : widget.readOnly
            ? widget.permissions.canViewChurchData ||
                widget.permissions.canEditAnyChurch
            : widget.permissions.canEditAnyChurch;

    final title = widget.createNew
        ? l10n.churchRegNewTitle
        : widget.readOnly
            ? l10n.churchRegViewTitle
            : widget.permissions.isSuperAdmin
                ? l10n.churchRegEditTitle
                : l10n.churchRegViewTitle;

    final lockedByBlock =
        _isBlocked && !widget.permissions.isSuperAdmin && !widget.createNew;
    final editable = !widget.readOnly && !lockedByBlock;

    return RoleGate(
      permissions: widget.permissions,
      allowed: allowed,
      deniedMessage: widget.createNew
          ? l10n.churchRegCreateDenied
          : widget.readOnly
              ? l10n.churchRegViewDenied
              : l10n.churchRegEditDenied,
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
                                      l10n.churchRegBlocked,
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
                          widget.readOnly
                              ? l10n.churchRegLogo
                              : l10n.churchRegLogoOptional,
                        ),
                        Center(child: _buildLogoPreview()),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.churchRegLogoHint,
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
                                label: Text(l10n.churchRegUploadLogo),
                              ),
                              if (_pickedLogoBytes != null) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _saving ? null : _clearPickedLogo,
                                  child: Text(l10n.churchRegRemoveLogo),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        FormSectionTitle(l10n.churchRegSectionInfo),
                        TextFormField(
                          controller: _nameController,
                          readOnly: widget.readOnly,
                          enabled: editable && !_saving,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: widget.readOnly
                                ? l10n.churchRegName
                                : l10n.churchRegNameRequired,
                            prefixIcon: const Icon(Icons.church_outlined),
                            border: const OutlineInputBorder(),
                            filled: widget.readOnly,
                          ),
                          validator: editable
                              ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.churchRegNameValidation;
                                  }
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _aliasController,
                          readOnly: widget.readOnly,
                          enabled: editable && !_saving,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            labelText: l10n.churchRegAlias,
                            hintText: widget.readOnly
                                ? null
                                : l10n.churchRegAliasHint,
                            helperText: widget.readOnly
                                ? null
                                : l10n.churchRegAliasHelper,
                            prefixIcon:
                                const Icon(Icons.account_balance_outlined),
                            border: const OutlineInputBorder(),
                            filled: widget.readOnly,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FormSectionTitle(
                          widget.readOnly
                              ? l10n.churchRegOfferingQr
                              : l10n.churchRegOfferingQrOptional,
                        ),
                        Center(child: _buildOfferingQrPreview()),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.churchRegOfferingQrHint,
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
                                onPressed: _saving || lockedByBlock
                                    ? null
                                    : _pickOfferingQr,
                                icon: const Icon(Icons.upload_outlined),
                                label: Text(l10n.churchRegUploadOfferingQr),
                              ),
                              if (_pickedOfferingQrBytes != null) ...[
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed:
                                      _saving ? null : _clearPickedOfferingQr,
                                  child: Text(l10n.churchRegRemoveLogo),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (widget.readOnly)
                          TextFormField(
                            controller: _addressController,
                            readOnly: true,
                            enabled: false,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: l10n.churchRegAddressSection,
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              border: const OutlineInputBorder(),
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
                            labelText: l10n.addressSearchRequired,
                            hintText: l10n.addressSearchHint,
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
                            label: Text(_saving ? l10n.commonSaving : l10n.commonSave),
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
