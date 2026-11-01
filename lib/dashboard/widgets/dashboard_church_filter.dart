import 'package:flutter/material.dart';

import '../../church/models/church_record.dart';

/// Selector de iglesia para dashboards del super administrador.
class DashboardChurchFilter extends StatelessWidget {
  const DashboardChurchFilter({
    super.key,
    required this.churches,
    required this.selectedChurchId,
    required this.enabled,
    required this.onChanged,
    required this.allChurchesLabel,
    required this.churchLabel,
  });

  final List<ChurchRecord> churches;
  final String? selectedChurchId;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final String allChurchesLabel;
  final String churchLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      key: ValueKey(selectedChurchId),
      isExpanded: true,
      initialValue: selectedChurchId,
      decoration: InputDecoration(
        labelText: churchLabel,
        prefixIcon: const Icon(Icons.church_outlined),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            allChurchesLabel,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        ...churches.map(
          (church) => DropdownMenuItem<String?>(
            value: church.id,
            child: Text(
              church.profile.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
      selectedItemBuilder: (context) => [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            allChurchesLabel,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        ...churches.map(
          (church) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              church.profile.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
