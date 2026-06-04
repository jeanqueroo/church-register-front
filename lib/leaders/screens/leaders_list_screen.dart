import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../models/church_leader.dart';
import '../services/leader_service.dart';
import 'leader_assigned_members_screen.dart';
import 'leader_detail_screen.dart';
import 'register_leader_screen.dart';

class LeadersListScreen extends StatelessWidget {
  const LeadersListScreen({
    super.key,
    required this.registeredBy,
    this.leaderService,
    this.permissions,
  });

  final String registeredBy;
  final LeaderService? leaderService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canViewLeadersList,
      child: _LeadersListBody(
        registeredBy: registeredBy,
        leaderService: leaderService,
        permissions: _permissions,
      ),
    );
  }
}

class _LeadersListBody extends StatelessWidget {
  const _LeadersListBody({
    required this.registeredBy,
    this.leaderService,
    required this.permissions,
  });

  final String registeredBy;
  final LeaderService? leaderService;
  final AppPermissions permissions;

  void _openAssignedMembers(BuildContext context, ChurchLeader leader) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderAssignedMembersScreen(
          leader: leader,
          registeredBy: registeredBy,
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, ChurchLeader leader) async {
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

  Future<void> _confirmDelete(BuildContext context, ChurchLeader leader) async {
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
    final service = leaderService ?? LeaderService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Líderes'),
      ),
      floatingActionButton: permissions.canRegisterLeader
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RegisterLeaderScreen(
                      registeredBy: registeredBy,
                      leaderService: service,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo'),
            )
          : null,
      body: StreamBuilder<List<ChurchLeader>>(
        stream: service.watchLeaders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar la lista.\n'
                  'Verifica Firestore y las reglas de la colección "leaders".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }

          final leaders = snapshot.data ?? [];

          if (leaders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.supervisor_account_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no hay líderes registrados',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: leaders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final leader = leaders[index];
              final parts = <String>[
                if (leader.cellCode != null) 'Célula ${leader.cellCode}',
                leader.mobilePhone,
                if (leader.email != null) leader.email!,
              ];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      leader.lastName.isNotEmpty
                          ? leader.lastName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text('${leader.lastName}, ${leader.firstName}'),
                  subtitle: Text(parts.join(' · ')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) => LeaderDetailScreen(
                                leader: leader,
                                registeredBy: registeredBy,
                                leaderService: service,
                                permissions: permissions,
                              ),
                            ),
                          );
                        case 'members':
                          _openAssignedMembers(context, leader);
                        case 'edit':
                          _openEdit(context, leader);
                        case 'delete':
                          _confirmDelete(context, leader);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('Ver detalle'),
                      ),
                      const PopupMenuItem(
                        value: 'members',
                        child: Text('Ver integrantes asignados'),
                      ),
                      if (permissions.canManageAll) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LeaderDetailScreen(
                          leader: leader,
                          registeredBy: registeredBy,
                          leaderService: service,
                          permissions: permissions,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
