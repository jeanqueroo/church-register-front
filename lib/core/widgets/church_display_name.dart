import 'package:flutter/material.dart';

import '../../church/models/church_profile.dart';
import '../../church/services/church_service.dart';
import '../theme/app_theme.dart';

String resolveChurchDisplayName(
  ChurchProfile? profile, {
  String fallback = appDisplayName,
}) {
  final name = profile?.name.trim();
  if (name != null && name.isNotEmpty) return name;
  return fallback;
}

/// Muestra el nombre de la iglesia del usuario o [fallback] si no hay sede.
class ChurchDisplayName extends StatelessWidget {
  const ChurchDisplayName({
    super.key,
    this.churchId,
    this.fallback = appDisplayName,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.churchService,
  });

  final String? churchId;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final ChurchService? churchService;

  @override
  Widget build(BuildContext context) {
    final id = churchId?.trim();
    if (id == null || id.isEmpty) {
      return Text(
        fallback,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final service = churchService ?? ChurchService();
    return StreamBuilder<ChurchProfile?>(
      stream: service.watchChurch(id),
      builder: (context, snapshot) {
        final label = resolveChurchDisplayName(snapshot.data, fallback: fallback);
        return Text(
          label,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
