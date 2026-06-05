import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../models/church_leader.dart';
import '../services/leader_service.dart';
import '../services/leaders_excel_export_service.dart';
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

class _LeadersListBody extends StatefulWidget {
  const _LeadersListBody({
    required this.registeredBy,
    this.leaderService,
    required this.permissions,
  });

  final String registeredBy;
  final LeaderService? leaderService;
  final AppPermissions permissions;

  @override
  State<_LeadersListBody> createState() => _LeadersListBodyState();
}

class _LeadersListBodyState extends State<_LeadersListBody> {
  final _searchController = TextEditingController();
  final _excelExportService = LeadersExcelExportService();
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(ChurchLeader leader, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      leader.lastName,
      leader.firstName,
      leader.fullName,
      leader.cellCode,
      leader.mobilePhone,
      leader.email,
      leader.churchOffice?.label,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  void _openAssignedMembers(BuildContext context, ChurchLeader leader) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderAssignedMembersScreen(
          leader: leader,
          registeredBy: widget.registeredBy,
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, ChurchLeader leader) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterLeaderScreen(
          registeredBy: widget.registeredBy,
          churchId: widget.permissions.churchId,
          leaderService: widget.leaderService,
          leaderToEdit: leader,
          permissions: widget.permissions,
        ),
      ),
    );
  }

  Future<void> _exportToExcel(List<ChurchLeader> leaders) async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      await _excelExportService.shareLeaders(leaders);
    } on LeadersExcelExportException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo exportar el listado. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
      await (widget.leaderService ?? LeaderService()).deleteLeader(id);
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
    final service = widget.leaderService ?? LeaderService();

    return StreamBuilder<List<ChurchLeader>>(
      stream: service.watchLeaders(churchId: widget.permissions.churchId),
      builder: (context, snapshot) {
        final leaders = snapshot.data ?? [];
        final filtered = leaders
            .where((l) => _matchesSearch(l, _searchController.text))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Líderes'),
            actions: [
              if (snapshot.hasData && leaders.isNotEmpty)
                IconButton(
                  tooltip: 'Descargar Excel',
                  onPressed: _exporting || filtered.isEmpty
                      ? null
                      : () => _exportToExcel(filtered),
                  icon: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                ),
            ],
          ),
          floatingActionButton: widget.permissions.canRegisterLeader
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RegisterLeaderScreen(
                          registeredBy: widget.registeredBy,
                          churchId: widget.permissions.churchId,
                          leaderService: service,
                          permissions: widget.permissions,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nuevo'),
                )
              : null,
          body: Builder(
            builder: (context) {
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, teléfono, correo o célula…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No hay coincidencias',
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
              final leader = filtered[index];
              final parts = <String>[
                if (leader.churchOffice != null) leader.churchOffice!.label,
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
                                registeredBy: widget.registeredBy,
                                leaderService: service,
                                permissions: widget.permissions,
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
                      if (widget.permissions.canManageAll) ...[
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
                          registeredBy: widget.registeredBy,
                          leaderService: service,
                          permissions: widget.permissions,
                        ),
                      ),
                    );
                  },
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
      },
    );
  }
}
