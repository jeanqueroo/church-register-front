import 'package:flutter/material.dart';

import '../models/church_leader.dart';

/// Campo de búsqueda para elegir un líder escribiendo nombre, célula, etc.
class LeaderSearchField extends StatefulWidget {
  const LeaderSearchField({
    super.key,
    required this.leaders,
    required this.selectedLeader,
    required this.onLeaderSelected,
    this.enabled = true,
    this.validator,
  });

  final List<ChurchLeader> leaders;
  final ChurchLeader? selectedLeader;
  final ValueChanged<ChurchLeader?> onLeaderSelected;
  final bool enabled;
  final FormFieldValidator<ChurchLeader>? validator;

  @override
  State<LeaderSearchField> createState() => _LeaderSearchFieldState();
}

class _LeaderSearchFieldState extends State<LeaderSearchField> {
  final _fieldKey = GlobalKey<FormFieldState<ChurchLeader>>();

  static String leaderLabel(ChurchLeader leader) {
    final parts = <String>[leader.fullName];
    if (leader.cellCode != null) {
      parts.add('Célula ${leader.cellCode}');
    }
    if (leader.gender != null) {
      parts.add(leader.gender!.label);
    }
    return parts.join(' · ');
  }

  static bool _matchesQuery(ChurchLeader leader, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final haystack = [
      leader.fullName,
      leader.firstName,
      leader.lastName,
      leader.cellCode,
      leader.gender?.label,
      leader.locality,
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains(q);
  }

  Iterable<ChurchLeader> _filter(String query) {
    final matches =
        widget.leaders.where((l) => _matchesQuery(l, query)).toList();
    matches.sort((a, b) => a.fullName.compareTo(b.fullName));
    return matches;
  }

  void _clearSelection() {
    widget.onLeaderSelected(null);
    _fieldKey.currentState?.didChange(null);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<ChurchLeader>(
      key: _fieldKey,
      initialValue: widget.selectedLeader,
      validator: widget.validator,
      builder: (field) {
        return Autocomplete<ChurchLeader>(
          displayStringForOption: leaderLabel,
          optionsMaxHeight: 260,
          optionsBuilder: (textEditingValue) {
            return _filter(textEditingValue.text);
          },
          onSelected: (leader) {
            field.didChange(leader);
            widget.onLeaderSelected(leader);
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            final label = widget.selectedLeader != null
                ? leaderLabel(widget.selectedLeader!)
                : '';
            if (label.isNotEmpty && textController.text != label) {
              textController.text = label;
            }

            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              enabled: widget.enabled,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Buscar líder *',
                hintText: 'Escribe letras del nombre o célula...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: widget.selectedLeader != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Quitar líder',
                        onPressed: widget.enabled ? _clearSelection : null,
                      )
                    : null,
                border: const OutlineInputBorder(),
                errorText: field.errorText,
              ),
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  field.didChange(null);
                  widget.onLeaderSelected(null);
                } else if (widget.selectedLeader != null &&
                    value != leaderLabel(widget.selectedLeader!)) {
                  field.didChange(null);
                  widget.onLeaderSelected(null);
                }
              },
              onFieldSubmitted: (_) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260, maxWidth: 400),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final leader = options.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          child: Text(
                            leader.lastName.isNotEmpty
                                ? leader.lastName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        title: Text(
                          leader.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          [
                            if (leader.cellCode != null)
                              'Célula ${leader.cellCode}',
                            if (leader.gender != null) leader.gender!.label,
                          ].join(' · '),
                        ),
                        dense: true,
                        onTap: () => onSelected(leader),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
