import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../models/church_member.dart';
import '../services/member_service.dart';
import 'register_member_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({
    super.key,
    required this.member,
    required this.registeredBy,
    this.memberService,
    this.permissions,
  });

  final ChurchMember member;
  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.fromRoles([]);

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMemberScreen(
          registeredBy: registeredBy,
          churchId: _permissions.churchId,
          memberService: memberService,
          memberToEdit: member,
          permissions: _permissions,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final id = member.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar integrante'),
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
      await (memberService ?? MemberService()).deleteMember(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Integrante eliminado')),
      );
      Navigator.of(context).pop(true);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(member.fullName),
        actions: [
          if (_permissions.canManageMembers) ...[
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
            title: 'Datos personales',
            rows: [
              _Row('Nombre', member.firstName),
              _Row('Apellidos', member.lastName),
              _Row('Género', member.gender?.label),
              _Row('Teléfono', member.phone),
              _Row('Fecha de nacimiento', _formatDate(member.birthDate)),
              _Row(
                'Edad',
                member.age != null ? '${member.age} años' : null,
              ),
              _Row('Ocupación', member.occupation),
              _Row('Estado civil', member.maritalStatus?.label),
              _Row(
                'Desea ser visitado',
                member.wantsVisit ? 'Sí' : 'No',
              ),
            ],
          ),
          _Section(
            title: 'Dirección',
            rows: [
              _Row('Calle', member.street),
              _Row('Número', member.streetNumber),
              _Row('Barrio', member.neighborhood),
              _Row('Localidad / Partido', member.locality),
              _Row('Estado / Provincia', member.stateProvince),
              _Row('Código postal', member.postalCode),
            ],
          ),
          if (member.assignedLeaderName != null)
            _Section(
              title: 'Líder asignado',
              rows: [
                _Row('Nombre', member.assignedLeaderName),
                _Row('Célula', member.assignedLeaderCellCode),
                _Row(
                  'Distancia',
                  member.assignedDistanceKm != null
                      ? '${member.assignedDistanceKm!.toStringAsFixed(1)} km'
                      : null,
                ),
              ],
            ),
          _Section(
            title: 'Horario para célula',
            rows: [
              _Row('Día', member.cellDay),
              _Row('Horario', member.cellTime),
              _Row('Zona', member.cellZone),
            ],
          ),
          if (member.observations != null && member.observations!.isNotEmpty)
            _Section(
              title: 'Observaciones',
              rows: [_Row('', member.observations)],
            ),
          _Section(
            title: 'Registro',
            rows: [
              _Row('Fecha del formulario', _formatDate(member.formDate)),
              _Row('Voluntario', member.volunteer),
              _Row('Registrado por', member.registeredBy),
            ],
          ),
          const SizedBox(height: 16),
          if (_permissions.canManageMembers) ...[
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar integrante'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar integrante'),
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
                        title: row.label.isNotEmpty ? Text(row.label) : null,
                        subtitle: Text(row.value!),
                        dense: row.label.isEmpty,
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
