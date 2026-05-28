import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../models/church_leader.dart';
import '../services/leader_service.dart';
import 'leader_assigned_members_screen.dart';
import 'register_leader_screen.dart';

class LeaderDetailScreen extends StatelessWidget {
  const LeaderDetailScreen({
    super.key,
    required this.leader,
    required this.registeredBy,
    this.leaderService,
    this.permissions,
  });

  final ChurchLeader leader;
  final String registeredBy;
  final LeaderService? leaderService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterLeaderScreen(
          registeredBy: registeredBy,
          leaderService: leaderService,
          leaderToEdit: leader,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final id = leader.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar líder'),
        content: Text(
          '¿Eliminar a ${leader.fullName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await (leaderService ?? LeaderService()).deleteLeader(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Líder eliminado')),
      );
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LeaderService.messageFromFirestoreException(e)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(leader.fullName),
        actions: [
          if (_permissions.canManageAll) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => _edit(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _delete(context),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Section(
            title: 'Datos del liderazgo',
            rows: [
              _Row('Apellido', leader.lastName),
              _Row('Nombres', leader.firstName),
              _Row('Género', leader.gender?.label),
              _Row('Cargo en la iglesia', leader.churchOffice?.label),
            ],
          ),
          _Section(
            title: 'Dirección',
            rows: [
              _Row('Calle', leader.street),
              _Row('Número', leader.streetNumber),
              _Row('Barrio', leader.neighborhood),
              _Row('Localidad / Partido', leader.locality),
              _Row('Estado / Provincia', leader.stateProvince),
              _Row('Código postal', leader.postalCode),
            ],
          ),
          _Section(
            title: 'Célula y contacto',
            rows: [
              _Row('Célula', leader.cellCode),
              _Row('Correo', leader.email),
              _Row('Celular / Móvil', leader.mobilePhone),
            ],
          ),
          _Section(
            title: 'Registro',
            rows: [
              _Row('Registrado por', leader.registeredBy),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LeaderAssignedMembersScreen(
                    leader: leader,
                    registeredBy: registeredBy,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.people_outlined),
            label: const Text('Ver nuevos creyentes asignados'),
          ),
          const SizedBox(height: 12),
          if (_permissions.canManageAll) ...[
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar líder'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar líder'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.hasValue).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: visible
                    .map(
                      (row) => ListTile(
                        title: Text(row.label),
                        subtitle: Text(row.value!),
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  bool get hasValue => value != null && value!.trim().isNotEmpty;
}
