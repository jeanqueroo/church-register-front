import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../models/cell_disciple_draft.dart';
import '../services/cell_service.dart';
import 'cell_disciple_draft_form_screen.dart';

/// Registra un discípulo sin célula asignada (disponible al crear células).
class RegisterUnassignedDiscipleScreen extends StatefulWidget {
  const RegisterUnassignedDiscipleScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.cellService,
    this.permissions,
  });

  final String registeredBy;
  final String? churchId;
  final CellService? cellService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterUnassignedDiscipleScreen> createState() =>
      _RegisterUnassignedDiscipleScreenState();
}

class _RegisterUnassignedDiscipleScreenState
    extends State<RegisterUnassignedDiscipleScreen> {
  late final CellService _cellService;

  @override
  void initState() {
    super.initState();
    _cellService = widget.cellService ?? CellService();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _persistDraft(CellDiscipleDraft draft) async {
    final l10n = context.l10n;
    final churchId = widget.churchId;
    if (churchId == null || churchId.isEmpty) {
      _showMessage(l10n.cellRegSelectDiscipleRequiresChurch);
      throw StateError('churchId missing');
    }

    try {
      await _cellService.addUnassignedDisciple(
        draft.toCellDisciple(
          cellId: '',
          cellCode: '',
          registeredBy: widget.registeredBy,
          churchId: churchId,
        ),
      );
      if (!mounted) return;
      _showMessage(l10n.cellDiscipleUnassignedSuccess);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(CellService.messageFromFirestoreException(e, l10n));
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canRegisterCellDisciple,
      deniedMessage: l10n.cellDiscipleDenied,
      child: CellDiscipleDraftFormScreen(
        title: l10n.cellDiscipleTitle,
        persistDraft: _persistDraft,
        header: Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.cellDiscipleUnassignedHint,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
