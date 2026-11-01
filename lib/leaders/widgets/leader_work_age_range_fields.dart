import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Campos opcionales de rango de edad pastoral (líder / supervisor).
class LeaderWorkAgeRangeFields extends StatelessWidget {
  const LeaderWorkAgeRangeFields({
    super.key,
    required this.fromController,
    required this.toController,
    required this.enabled,
    this.requiredWhenEitherFilled = true,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final bool enabled;
  final bool requiredWhenEitherFilled;

  static int? parseAge(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  static String? validatePair({
    required AppLocalizations l10n,
    required String? fromText,
    required String? toText,
    required bool requiredWhenEitherFilled,
  }) {
    final fromRaw = fromText?.trim() ?? '';
    final toRaw = toText?.trim() ?? '';
    final hasFrom = fromRaw.isNotEmpty;
    final hasTo = toRaw.isNotEmpty;

    if (!hasFrom && !hasTo) return null;

    if (requiredWhenEitherFilled && hasFrom != hasTo) {
      return hasFrom
          ? l10n.leaderWorkAgeToRequired
          : l10n.leaderWorkAgeFromRequired;
    }

    final from = hasFrom ? int.tryParse(fromRaw) : null;
    final to = hasTo ? int.tryParse(toRaw) : null;
    if (hasFrom && (from == null || from < 0 || from > 120)) {
      return l10n.leaderWorkAgeInvalid;
    }
    if (hasTo && (to == null || to < 0 || to > 120)) {
      return l10n.leaderWorkAgeInvalid;
    }
    if (from != null && to != null && from > to) {
      return l10n.leaderWorkAgeOrderInvalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.leaderWorkAgeRange,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.leaderWorkAgeRangeHelper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: fromController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: l10n.leaderWorkAgeFrom,
                  prefixIcon: const Icon(Icons.arrow_upward_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (_) => validatePair(
                  l10n: l10n,
                  fromText: fromController.text,
                  toText: toController.text,
                  requiredWhenEitherFilled: requiredWhenEitherFilled,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: toController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: l10n.leaderWorkAgeTo,
                  prefixIcon: const Icon(Icons.arrow_downward_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (_) => validatePair(
                  l10n: l10n,
                  fromText: fromController.text,
                  toText: toController.text,
                  requiredWhenEitherFilled: requiredWhenEitherFilled,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
