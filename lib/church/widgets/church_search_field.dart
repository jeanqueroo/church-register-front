import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../models/church_record.dart';

/// Selector de iglesia con lista y buscador (estilo select + modal).
class ChurchSearchField extends StatefulWidget {
  const ChurchSearchField({
    super.key,
    required this.churches,
    required this.selectedChurch,
    required this.onChurchSelected,
    this.enabled = true,
    this.validator,
    this.labelText,
  });

  final List<ChurchRecord> churches;
  final ChurchRecord? selectedChurch;
  final ValueChanged<ChurchRecord?> onChurchSelected;
  final bool enabled;
  final FormFieldValidator<ChurchRecord>? validator;
  final String? labelText;

  static String churchDisplayName(ChurchRecord church, AppLocalizations l10n) {
    return church.name.isNotEmpty ? church.name : l10n.commonNoName;
  }

  @override
  State<ChurchSearchField> createState() => _ChurchSearchFieldState();
}

class _ChurchSearchFieldState extends State<ChurchSearchField> {
  final _fieldKey = GlobalKey<FormFieldState<ChurchRecord>>();
  late final TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncDisplay(widget.selectedChurch);
    });
  }

  @override
  void didUpdateWidget(ChurchSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChurch?.id != widget.selectedChurch?.id) {
      _syncDisplay(widget.selectedChurch);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final field = _fieldKey.currentState;
        if (field == null) return;
        if (field.value?.id == widget.selectedChurch?.id) return;
        field.didChange(widget.selectedChurch);
      });
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  void _syncDisplay(ChurchRecord? church) {
    final l10n = context.l10n;
    final text = church == null
        ? ''
        : ChurchSearchField.churchDisplayName(church, l10n);
    if (_displayController.text != text) {
      _displayController.text = text;
    }
  }

  void _clearSelection() {
    _displayController.clear();
    _fieldKey.currentState?.didChange(null);
    widget.onChurchSelected(null);
  }

  Future<void> _openPicker(FormFieldState<ChurchRecord> field) async {
    final picked = await showModalBottomSheet<ChurchRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _ChurchPickerSheet(
          churches: widget.churches,
          initialSelection: field.value ?? widget.selectedChurch,
        );
      },
    );

    if (picked == null || !mounted) return;

    _syncDisplay(picked);
    field.didChange(picked);
    widget.onChurchSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FormField<ChurchRecord>(
      key: _fieldKey,
      initialValue: widget.selectedChurch,
      validator: widget.validator,
      builder: (field) {
        final selected = field.value ?? widget.selectedChurch;
        final address = selected?.address.trim() ?? '';

        return TextFormField(
          controller: _displayController,
          readOnly: true,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.labelText ?? l10n.churchSearchLabel,
            hintText: l10n.churchSearchTitle,
            prefixIcon: const Icon(Icons.church_outlined),
            suffixIcon: selected != null && widget.enabled
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.churchSearchClear,
                    onPressed: _clearSelection,
                  )
                : const Icon(Icons.arrow_drop_down),
            helperText: address.isNotEmpty ? address : null,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          onTap: widget.enabled ? () => _openPicker(field) : null,
        );
      },
    );
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
    final l10n = context.l10n;
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
                l10n.churchSearchTitle,
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
                decoration: InputDecoration(
                  hintText: l10n.churchSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
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
                              ? l10n.churchSearchEmpty
                              : l10n.churchSearchNoMatches(_query),
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
                        final name =
                            ChurchSearchField.churchDisplayName(church, l10n);
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
