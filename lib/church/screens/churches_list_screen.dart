import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../models/church_record.dart';
import '../services/church_service.dart';
import 'register_church_screen.dart';

/// Lista de iglesias para el super administrador (ver, editar y bloquear).
class ChurchesListScreen extends StatelessWidget {
  const ChurchesListScreen({
    super.key,
    required this.updatedBy,
    required this.permissions,
    this.churchService,
  });

  final String updatedBy;
  final AppPermissions permissions;
  final ChurchService? churchService;

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewChurchesList,
      deniedMessage: 'Solo el super administrador puede gestionar iglesias.',
      child: _ChurchesListBody(
        updatedBy: updatedBy,
        permissions: permissions,
        churchService: churchService,
      ),
    );
  }
}

class _ChurchesListBody extends StatefulWidget {
  const _ChurchesListBody({
    required this.updatedBy,
    required this.permissions,
    this.churchService,
  });

  final String updatedBy;
  final AppPermissions permissions;
  final ChurchService? churchService;

  @override
  State<_ChurchesListBody> createState() => _ChurchesListBodyState();
}

class _ChurchesListBodyState extends State<_ChurchesListBody> {
  final _searchController = TextEditingController();
  late final ChurchService _churchService;
  bool _hideBlocked = false;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _churchService = widget.churchService ?? ChurchService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openCreate() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterChurchScreen(
          updatedBy: widget.updatedBy,
          permissions: widget.permissions,
          churchService: _churchService,
          createNew: true,
        ),
      ),
    );
  }

  void _openEdit(ChurchRecord record) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterChurchScreen(
          updatedBy: widget.updatedBy,
          permissions: widget.permissions,
          churchService: _churchService,
          churchId: record.id,
        ),
      ),
    );
  }

  bool _matchesSearch(ChurchRecord record, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      record.name,
      record.address,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  List<ChurchRecord> _applyFilters(List<ChurchRecord> churches) {
    final query = _searchController.text;
    return churches
        .where((c) => !_hideBlocked || !c.isBlocked)
        .where((c) => _matchesSearch(c, query))
        .toList();
  }

  Future<void> _confirmBlock(ChurchRecord record, {required bool block}) async {
    if (!widget.permissions.canBlockChurch || _actionInProgress) return;

    final name = record.name.isNotEmpty ? record.name : '(Sin nombre)';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? 'Bloquear iglesia' : 'Desbloquear iglesia'),
        content: Text(
          block
              ? '¿Bloquear "$name"?\n\n'
                  'No se podrá asignar a nuevos administradores. '
                  'Los administradores ya vinculados conservan su cuenta, '
                  'pero la sede quedará inactiva.'
              : '¿Desbloquear "$name" y volver a permitir su uso?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(block ? 'Bloquear' : 'Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await _churchService.setChurchBlocked(
        churchId: record.id,
        blocked: block,
        updatedBy: widget.updatedBy,
      );
      if (!mounted) return;
      _showMessage(block ? 'Iglesia bloqueada' : 'Iglesia desbloqueada');
    } catch (e) {
      if (!mounted) return;
      _showMessage(ChurchService.messageFromException(e));
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _onMenuAction(String action, ChurchRecord record) {
    switch (action) {
      case 'edit':
        _openEdit(record);
      case 'block':
        _confirmBlock(record, block: true);
      case 'unblock':
        _confirmBlock(record, block: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iglesias'),
      ),
      floatingActionButton: widget.permissions.canCreateChurch
          ? FloatingActionButton.extended(
              onPressed: _actionInProgress ? null : _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
      body: StreamBuilder<List<ChurchRecord>>(
        stream: _churchService.watchChurches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar las iglesias.\n'
                  'Verifica Firestore y las reglas de la colección "churches".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }

          final churches = snapshot.data ?? [];
          final filtered = _applyFilters(churches);
          final blockedCount = churches.where((c) => c.isBlocked).length;

          if (churches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.church_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no hay iglesias registradas',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (widget.permissions.canCreateChurch)
                      FilledButton.icon(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar iglesia'),
                      ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o dirección…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (blockedCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: FilterChip(
                    label: Text(
                      _hideBlocked
                          ? 'Mostrar bloqueadas ($blockedCount)'
                          : 'Ocultar bloqueadas ($blockedCount)',
                    ),
                    selected: _hideBlocked,
                    onSelected: _actionInProgress
                        ? null
                        : (v) => setState(() => _hideBlocked = v),
                  ),
                ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _searchController.text.trim().isEmpty && _hideBlocked
                          ? 'Todas las iglesias están bloqueadas'
                          : 'No hay coincidencias',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final record = filtered[index];
                      final logoUrl = record.profile.logoUrl;
                      final blocked = record.isBlocked;

                      return Card(
                        color: blocked
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : null,
                        child: ListTile(
                          isThreeLine: record.address.trim().isNotEmpty,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            backgroundImage: logoUrl != null &&
                                    logoUrl.trim().isNotEmpty
                                ? NetworkImage(logoUrl)
                                : null,
                            child: logoUrl == null || logoUrl.isEmpty
                                ? Icon(
                                    Icons.church,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record.name.isNotEmpty
                                      ? record.name
                                      : '(Sin nombre)',
                                ),
                              ),
                              if (blocked)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Chip(
                                    label: const Text('Bloqueada'),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: record.address.trim().isNotEmpty
                              ? Text(record.address)
                              : null,
                          onTap: _actionInProgress
                              ? null
                              : () => _openEdit(record),
                          trailing: PopupMenuButton<String>(
                            enabled: !_actionInProgress,
                            onSelected: (value) =>
                                _onMenuAction(value, record),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              if (widget.permissions.canBlockChurch)
                                PopupMenuItem(
                                  value: blocked ? 'unblock' : 'block',
                                  child: Text(
                                    blocked ? 'Desbloquear' : 'Bloquear',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
