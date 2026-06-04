import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/services/excel_export_service.dart';
import '../../core/utils/list_search.dart';
import '../../core/widgets/export_excel_icon_button.dart';
import '../../core/widgets/person_list_search_field.dart';
import '../models/church_member.dart';
import '../services/member_service.dart';
import 'member_detail_screen.dart';
import 'register_member_screen.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({
    super.key,
    required this.registeredBy,
    this.memberService,
    this.permissions,
  });

  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canViewMembersList,
      child: _MembersListBody(
        registeredBy: registeredBy,
        memberService: memberService,
        permissions: _permissions,
      ),
    );
  }
}

class _MembersListBody extends StatefulWidget {
  const _MembersListBody({
    required this.registeredBy,
    this.memberService,
    required this.permissions,
  });

  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions permissions;

  @override
  State<_MembersListBody> createState() => _MembersListBodyState();
}

class _MembersListBodyState extends State<_MembersListBody> {
  final _searchController = TextEditingController();
  List<ChurchMember> _membersForExport = [];
  bool _canExport = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportToExcel() {
    return ExcelExportService.instance.shareMembersExcel(
      members: _membersForExport,
      fileName: 'nuevos_creyentes_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void _syncMembersForExport(List<ChurchMember> members) {
    _membersForExport = members;
    final canExport = members.isNotEmpty;
    if (canExport == _canExport) return;
    _canExport = canExport;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _openEdit(BuildContext context, ChurchMember member) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMemberScreen(
          registeredBy: widget.registeredBy,
          memberService: widget.memberService,
          memberToEdit: member,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ChurchMember member) async {
    final id = member.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nuevo creyente'),
        content: Text(
          '¿Eliminar a ${member.fullName}? Esta acción no se puede deshacer.',
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
      await (widget.memberService ?? MemberService()).deleteMember(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nuevo creyente eliminado')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MemberService.messageFromFirestoreException(e)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.memberService ?? MemberService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevos creyentes'),
        actions: [
          ExportExcelIconButton(
            enabled: _canExport,
            onExport: _exportToExcel,
          ),
        ],
      ),
      floatingActionButton: widget.permissions.canRegisterMember
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => RegisterMemberScreen(
                      registeredBy: widget.registeredBy,
                      memberService: service,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo'),
            )
          : null,
      body: StreamBuilder<List<ChurchMember>>(
        stream: service.watchMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar la lista.\nVerifica Firestore en Firebase Console.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            );
          }

          final members = snapshot.data ?? [];
          _syncMembersForExport(members);
          final query = _searchController.text;
          final filtered = members
              .where((m) => memberMatchesSearch(m, query))
              .toList();

          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no hay nuevos creyentes registrados',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pulsa "Nuevo" para registrar al primero.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PersonListSearchField(
                controller: _searchController,
                hintText: 'Buscar por nombre, teléfono o líder…',
                onChanged: (_) => setState(() {}),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: PersonListSearchEmptyState(query: query),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = filtered[index];
              final subtitleParts = <String>[
                member.phone,
                if (member.assignedLeaderName != null)
                  'Líder: ${member.assignedLeaderName}',
                if (member.locality != null) member.locality!,
                'Fecha: ${_formatDate(member.formDate)}',
              ];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      member.fullName.isNotEmpty
                          ? member.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(subtitleParts.join(' · ')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) => MemberDetailScreen(
                                member: member,
                                registeredBy: widget.registeredBy,
                                memberService: service,
                                permissions: widget.permissions,
                              ),
                            ),
                          );
                        case 'edit':
                          _openEdit(context, member);
                        case 'delete':
                          _confirmDelete(context, member);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('Ver detalle'),
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
                        builder: (_) => MemberDetailScreen(
                          member: member,
                          registeredBy: widget.registeredBy,
                          memberService: service,
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
  }
}
