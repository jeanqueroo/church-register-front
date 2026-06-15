import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../models/cell_disciple_selection.dart';
import '../services/cell_service.dart';

class SelectExistingDiscipleScreen extends StatefulWidget {
  const SelectExistingDiscipleScreen({
    super.key,
    this.churchId,
    this.cellService,
    this.excludedKeys = const {},
  });

  final String? churchId;
  final CellService? cellService;
  final Set<String> excludedKeys;

  @override
  State<SelectExistingDiscipleScreen> createState() =>
      _SelectExistingDiscipleScreenState();
}

class _SelectExistingDiscipleScreenState
    extends State<SelectExistingDiscipleScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<ChurchDiscipleEntry> _entries = [];
  bool _loading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (widget.churchId == null || widget.churchId!.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _entries = [];
          _loading = false;
        });
        return;
      }

      final service = widget.cellService ?? CellService();
      final entries = await service.fetchUnassignedDisciples(
        churchId: widget.churchId,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  bool _matchesSearch(ChurchDiscipleEntry entry, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      entry.disciple.fullName,
      entry.disciple.mobilePhone,
      entry.disciple.email,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  void _selectEntry(ChurchDiscipleEntry entry) {
    final l10n = context.l10n;
    if (widget.excludedKeys.contains(entry.key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cellRegDiscipleAlreadySelected)),
      );
      return;
    }

    Navigator.of(context).pop(
      CellDiscipleSelection.existing(
        disciple: entry.disciple,
        discipleId: entry.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _entries
        .where((entry) => _matchesSearch(entry, _searchController.text))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cellRegSelectDiscipleTitle),
      ),
      body: _buildBody(context, l10n, filtered),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<ChurchDiscipleEntry> filtered,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.cellRegSelectDiscipleLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadEntries,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.churchId == null || widget.churchId!.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.cellRegSelectDiscipleRequiresChurch,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.cellRegSelectDiscipleEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
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
                      l10n.cellRegSelectDiscipleHint,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.cellRegSelectDiscipleSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(l10n.commonNoMatches))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final disciple = entry.disciple;
                    final isExcluded = widget.excludedKeys.contains(entry.key);
                    final parts = <String>[
                      disciple.mobilePhone,
                      if (disciple.email != null && disciple.email!.isNotEmpty)
                        disciple.email!,
                    ];

                    return Card(
                      color: isExcluded
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            disciple.fullName.isNotEmpty
                                ? disciple.fullName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(disciple.fullName),
                        subtitle: Text(parts.join(' · ')),
                        trailing: isExcluded
                            ? Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.outline,
                              )
                            : const Icon(Icons.add_circle_outline),
                        enabled: !isExcluded,
                        onTap: isExcluded ? null : () => _selectEntry(entry),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
