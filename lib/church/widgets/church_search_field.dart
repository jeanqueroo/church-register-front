import 'package:flutter/material.dart';

import '../models/church_record.dart';

/// Selector de iglesia con lista y buscador (estilo select + modal).
class ChurchSearchField extends StatelessWidget {
  const ChurchSearchField({
    super.key,
    required this.churches,
    required this.selectedChurch,
    required this.onChurchSelected,
    this.enabled = true,
    this.validator,
    this.labelText = 'Iglesia *',
  });

  final List<ChurchRecord> churches;
  final ChurchRecord? selectedChurch;
  final ValueChanged<ChurchRecord?> onChurchSelected;
  final bool enabled;
  final FormFieldValidator<ChurchRecord>? validator;
  final String labelText;

  static String churchDisplayName(ChurchRecord church) {
    return church.name.isNotEmpty ? church.name : '(Sin nombre)';
  }

  @override
  Widget build(BuildContext context) {
    return FormField<ChurchRecord>(
      initialValue: selectedChurch,
      validator: validator,
      builder: (field) {
        final selected = field.value;
        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: enabled ? () => _openPicker(context, field) : null,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: labelText,
                  prefixIcon: const Icon(Icons.church_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected != null && enabled)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Quitar selección',
                          onPressed: () {
                            field.didChange(null);
                            onChurchSelected(null);
                          },
                        ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                  errorText: hasError ? field.errorText : null,
                  enabled: enabled,
                ),
                isEmpty: selected == null,
                child: Text(
                  selected == null
                      ? 'Seleccionar iglesia'
                      : churchDisplayName(selected),
                  style: selected == null
                      ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (selected != null && selected.address.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  selected.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    FormFieldState<ChurchRecord> field,
  ) async {
    final picked = await showModalBottomSheet<ChurchRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _ChurchPickerSheet(
          churches: churches,
          initialSelection: field.value,
        );
      },
    );

    if (picked == null) return;

    field.didChange(picked);
    onChurchSelected(picked);
  }
}

class _ChurchPickerSheet extends StatefulWidget {
  const _ChurchPickerSheet({
    required this.churches,
    this.initialSelection,
  });

  final List<ChurchRecord> churches;
  final ChurchRecord? initialSelection;

  @override
  State<_ChurchPickerSheet> createState() => _ChurchPickerSheetState();
}

class _ChurchPickerSheetState extends State<_ChurchPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ChurchRecord church) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [church.name, church.address].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  List<ChurchRecord> get _filtered {
    final seen = <String>{};
    final results = <ChurchRecord>[];
    for (final church in widget.churches) {
      if (!_matches(church)) continue;
      if (seen.add(church.id)) results.add(church);
    }
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Seleccionar iglesia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o dirección…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.trim().isEmpty
                              ? 'No hay iglesias disponibles'
                              : 'No hay coincidencias para "$_query"',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final church = filtered[index];
                        final isSelected =
                            widget.initialSelection?.id == church.id;
                        final name = ChurchSearchField.churchDisplayName(church);
                        final address = church.address.trim();

                        return ListTile(
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.church_outlined,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle:
                              address.isNotEmpty ? Text(address) : null,
                          onTap: () => Navigator.pop(context, church),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
