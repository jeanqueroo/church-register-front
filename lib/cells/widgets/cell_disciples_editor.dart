import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../models/cell_disciple_draft.dart';
import '../models/cell_disciple_selection.dart';
import '../screens/cell_disciple_draft_form_screen.dart';
import '../screens/select_existing_disciple_screen.dart';
import '../services/cell_service.dart';

/// Editor de discípulos para el registro de célula (máximo [maxDisciples]).
class CellDisciplesEditor extends StatelessWidget {
  const CellDisciplesEditor({
    super.key,
    required this.selections,
    required this.onChanged,
    required this.cellCode,
    this.churchId,
    this.cellService,
    this.maxDisciples = 3,
    this.enabled = true,
  });

  static const int defaultMaxDisciples = 3;

  final List<CellDiscipleSelection> selections;
  final ValueChanged<List<CellDiscipleSelection>> onChanged;
  final String? cellCode;
  final String? churchId;
  final CellService? cellService;
  final int maxDisciples;
  final bool enabled;

  Set<String> get _excludedKeys => selections
      .where((selection) => selection.isExisting)
      .map((selection) => selection.existingKey)
      .toSet();

  Future<void> _openNewForm(
    BuildContext context, {
    CellDiscipleDraft? initial,
    int? editIndex,
  }) async {
    final l10n = context.l10n;
    final draft = await Navigator.of(context).push<CellDiscipleDraft>(
      MaterialPageRoute<CellDiscipleDraft>(
        builder: (_) => CellDiscipleDraftFormScreen(
          title: editIndex == null
              ? l10n.cellRegAddDisciple
              : l10n.cellRegEditDisciple,
          cellCode: cellCode,
          initial: initial,
        ),
      ),
    );
    if (draft == null) return;

    final updated = List<CellDiscipleSelection>.from(selections);
    final selection = CellDiscipleSelection.newDisciple(draft);
    if (editIndex != null) {
      updated[editIndex] = selection;
    } else {
      updated.add(selection);
    }
    onChanged(updated);
  }

  Future<void> _openExistingPicker(BuildContext context) async {
    final l10n = context.l10n;
    if (churchId == null || churchId!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellRegSelectDiscipleRequiresChurch)),
      );
      return;
    }
    if (selections.length >= maxDisciples) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellRegDisciplesMaxReached(maxDisciples))),
      );
      return;
    }

    final selection = await Navigator.of(context).push<CellDiscipleSelection>(
      MaterialPageRoute<CellDiscipleSelection>(
        builder: (_) => SelectExistingDiscipleScreen(
          churchId: churchId,
          cellService: cellService,
          excludedKeys: _excludedKeys,
        ),
      ),
    );
    if (selection == null) return;

    final updated = List<CellDiscipleSelection>.from(selections)..add(selection);
    onChanged(updated);
  }

  void _remove(int index) {
    final updated = List<CellDiscipleSelection>.from(selections)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canAdd = enabled && selections.length < maxDisciples;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.cellRegSectionDisciples,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            Text(
              l10n.cellRegDisciplesCount(selections.length, maxDisciples),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.cellRegDisciplesHint(maxDisciples),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        if (selections.isEmpty)
          Text(
            l10n.cellRegDisciplesEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          ...selections.asMap().entries.map((entry) {
            final index = entry.key;
            final selection = entry.value;
            final disciple = selection.draft;
            final subtitleParts = <String>[
              disciple.mobilePhone,
              if (selection.isExisting) l10n.cellRegDiscipleUnassignedBadge,
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      disciple.fullName.isNotEmpty
                          ? disciple.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(disciple.fullName)),
                      if (selection.isExisting)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Chip(
                            label: Text(
                              l10n.cellRegDiscipleUnassignedBadge,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(subtitleParts.join(' · ')),
                  trailing: enabled
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!selection.isExisting)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.commonEdit,
                                onPressed: () => _openNewForm(
                                  context,
                                  initial: disciple,
                                  editIndex: index,
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: l10n.commonDelete,
                              onPressed: () => _remove(index),
                            ),
                          ],
                        )
                      : null,
                  onTap: enabled && !selection.isExisting
                      ? () => _openNewForm(
                            context,
                            initial: disciple,
                            editIndex: index,
                          )
                      : null,
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAdd ? () => _openNewForm(context) : null,
                icon: const Icon(Icons.person_add_outlined),
                label: Text(l10n.cellRegAddDisciple),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAdd ? () => _openExistingPicker(context) : null,
                icon: const Icon(Icons.person_search_outlined),
                label: Text(l10n.cellRegSelectExistingDisciple),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
