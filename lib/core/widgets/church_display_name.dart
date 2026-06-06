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

/// Dónde se muestra el nombre; ajusta líneas y tamaño según el espacio.
enum ChurchDisplayNameLayout {
  /// Barra superior: una línea, escala si el texto es largo.
  appBar,

  /// Menú lateral: hasta dos líneas en pantallas estrechas.
  drawer,

  /// Formularios y bloques de contenido.
  inline,
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
    this.layout = ChurchDisplayNameLayout.inline,
    this.churchService,
  });

  final String? churchId;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final ChurchDisplayNameLayout layout;
  final ChurchService? churchService;

  int _effectiveMaxLines(double width) {
    switch (layout) {
      case ChurchDisplayNameLayout.appBar:
        return 1;
      case ChurchDisplayNameLayout.drawer:
        return width < 340 ? 2 : 1;
      case ChurchDisplayNameLayout.inline:
        return width < 320 && maxLines > 1 ? 2 : maxLines;
    }
  }

  TextStyle _effectiveStyle(BuildContext context, double width) {
    final base = style ?? Theme.of(context).textTheme.titleMedium;
    final fontSize = base?.fontSize ?? 16;
    final scale = switch (layout) {
      ChurchDisplayNameLayout.appBar =>
        width < 300 ? 0.82 : width < 360 ? 0.9 : 1.0,
      ChurchDisplayNameLayout.drawer =>
        width < 300 ? 0.88 : width < 360 ? 0.94 : 1.0,
      ChurchDisplayNameLayout.inline => width < 320 ? 0.92 : 1.0,
    };
    return (base ?? const TextStyle()).copyWith(
      fontSize: fontSize * scale,
    );
  }

  Alignment _alignmentFor(TextAlign? align) {
    return switch (align) {
      TextAlign.center => Alignment.center,
      TextAlign.right => Alignment.centerRight,
      TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }

  Widget _buildLabel(String label, BuildContext context, double maxWidth) {
    final effectiveMaxLines = _effectiveMaxLines(maxWidth);
    final effectiveStyle = _effectiveStyle(context, maxWidth);
    final align = textAlign ?? TextAlign.start;

    final text = Text(
      label,
      style: effectiveStyle,
      textAlign: align,
      maxLines: effectiveMaxLines,
      overflow: TextOverflow.ellipsis,
    );

    if (layout == ChurchDisplayNameLayout.appBar) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: _alignmentFor(align),
        child: Text(
          label,
          style: effectiveStyle,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final id = churchId?.trim();
        if (id == null || id.isEmpty) {
          return _buildLabel(fallback, context, maxWidth);
        }

        final service = churchService ?? ChurchService();
        return StreamBuilder<ChurchProfile?>(
          stream: service.watchChurch(id),
          builder: (context, snapshot) {
            final label = resolveChurchDisplayName(
              snapshot.data,
              fallback: fallback,
            );
            return _buildLabel(label, context, maxWidth);
          },
        );
      },
    );
  }
}
