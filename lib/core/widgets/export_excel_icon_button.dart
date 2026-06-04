import 'package:flutter/material.dart';

/// Botón de AppBar para exportar una lista a Excel y compartir/descargar.
class ExportExcelIconButton extends StatelessWidget {
  const ExportExcelIconButton({
    super.key,
    required this.onExport,
    this.enabled = true,
  });

  final Future<void> Function() onExport;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.download_outlined),
      tooltip: 'Descargar Excel',
      onPressed: !enabled
          ? null
          : () async {
              try {
                await onExport();
              } catch (e) {
                if (!context.mounted) return;
                final message = e is StateError
                    ? e.message
                    : 'No se pudo exportar a Excel.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
    );
  }
}
