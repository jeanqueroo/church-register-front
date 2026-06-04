import 'package:flutter/material.dart';

/// Campo de búsqueda para listas de personas (nombre, teléfono, etc.).
class PersonListSearchField extends StatelessWidget {
  const PersonListSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Buscar por nombre, teléfono o dirección…',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return SearchBar(
            controller: controller,
            hintText: hintText,
            leading: const Icon(Icons.search),
            trailing: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
            ],
            onChanged: onChanged,
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          );
        },
      ),
    );
  }
}

/// Mensaje cuando el filtro no devuelve resultados.
class PersonListSearchEmptyState extends StatelessWidget {
  const PersonListSearchEmptyState({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay coincidencias para "$query".\nPrueba con otro nombre o teléfono.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
