import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../models/cell_disciple_draft.dart';
import '../models/church_cell.dart';
import '../services/cell_service.dart';
import 'cell_disciple_draft_form_screen.dart';

class RegisterCellDiscipleScreen extends StatefulWidget {
  const RegisterCellDiscipleScreen({
    super.key,
    required this.cell,
    required this.registeredBy,
    this.cellService,
    this.permissions,
  });

  final ChurchCell cell;
  final String registeredBy;
  final CellService? cellService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<RegisterCellDiscipleScreen> createState() =>
      _RegisterCellDiscipleScreenState();
}

class _RegisterCellDiscipleScreenState extends State<RegisterCellDiscipleScreen> {
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
    final cellId = widget.cell.id;
    if (cellId == null || cellId.isEmpty) {
      _showMessage(l10n.cellDiscipleCellMissing);
      throw StateError('cellId missing');
    }

    try {
      await _cellService.addDisciple(
        draft.toCellDisciple(
          cellId: cellId,
          cellCode: widget.cell.code,
          registeredBy: widget.registeredBy,
          churchId: widget.cell.churchId,
        ),
      );
      if (!mounted) return;
      _showMessage(l10n.cellDiscipleSuccess);
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
        cellCode: widget.cell.code,
        persistDraft: _persistDraft,
        header: Card(
          child: ListTile(
            leading: const Icon(Icons.groups_2_outlined),
            title: Text(l10n.cellDiscipleForCell),
            subtitle: Text(widget.cell.displayLabel),
          ),
        ),
      ),
    );
  }
}
