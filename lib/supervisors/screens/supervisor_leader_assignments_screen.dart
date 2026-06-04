import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/utils/list_search.dart';
import '../../core/widgets/person_list_search_field.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
import '../models/supervisor_account.dart';
import '../services/supervisor_assignment_service.dart';

/// Asigna líderes a un supervisor (admin) o consulta los propios (supervisor).
class SupervisorLeaderAssignmentsScreen extends StatefulWidget {
  const SupervisorLeaderAssignmentsScreen({
    super.key,
    required this.session,
    this.assignmentService,
    this.leaderService,
  });

  final UserSession session;
  final SupervisorAssignmentService? assignmentService;
  final LeaderService? leaderService;

  @override
  State<SupervisorLeaderAssignmentsScreen> createState() =>
      _SupervisorLeaderAssignmentsScreenState();
}

class _SupervisorLeaderAssignmentsScreenState
    extends State<SupervisorLeaderAssignmentsScreen> {
  final _searchController = TextEditingController();
  final _assignmentService = SupervisorAssignmentService();
  late final LeaderService _leaderService;

  List<SupervisorAccount> _supervisors = [];
  List<ChurchLeader> _leaders = [];
  List<ChurchLeader> _assignableLeaders = [];
  Map<String, String> _leaderOwnerBySupervisorUid = {};
  SupervisorAccount? _selectedSupervisor;
  Set<String> _selectedLeaderIds = {};
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  AppPermissions get _permissions => widget.session.permissions;
  bool get _isAdmin => _permissions.isAdmin;

  @override
  void initState() {
    super.initState();
    _leaderService = widget.leaderService ?? LeaderService();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      if (_isAdmin) {
        final supervisors =
            await _assignmentService.fetchSupervisorAccounts();
        final assignable = await _leaderService.fetchAssignableLeaders();
        final ownerMap =
            await _assignmentService.fetchLeaderToSupervisorMap();
        assignable.sort(
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
        if (!mounted) return;
        final assignableIds =
            assignable.map((l) => l.id).whereType<String>().toSet();
        final firstSupervisor =
            supervisors.isNotEmpty ? supervisors.first : null;
        setState(() {
          _assignableLeaders = assignable;
          _leaderOwnerBySupervisorUid = ownerMap;
          _supervisors = supervisors;
          _selectedSupervisor = firstSupervisor;
          _selectedLeaderIds = firstSupervisor == null
              ? {}
              : firstSupervisor.supervisedLeaderIds
                  .where(assignableIds.contains)
                  .toSet();
          _loading = false;
        });
      } else {
        final assigned = await _assignmentService.fetchAssignedLeaders(
          widget.session.uid,
          leaderService: _leaderService,
        );
        if (!mounted) return;
        setState(() {
          _leaders = assigned;
          _selectedLeaderIds =
              assigned.map((l) => l.id).whereType<String>().toSet();
          _loading = false;
        });
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = SupervisorAssignmentService.messageFromFirestoreException(
          e,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'No se pudo cargar la información.';
      });
    }
  }

  void _onSupervisorChanged(SupervisorAccount? supervisor) {
    if (supervisor == null) return;
    final assignableIds =
        _assignableLeaders.map((l) => l.id).whereType<String>().toSet();
    setState(() {
      _selectedSupervisor = supervisor;
      _selectedLeaderIds = supervisor.supervisedLeaderIds
          .where(assignableIds.contains)
          .toSet();
    });
  }

  void _toggleLeader(String leaderId, bool selected) {
    setState(() {
      if (selected) {
        _selectedLeaderIds.add(leaderId);
      } else {
        _selectedLeaderIds.remove(leaderId);
      }
    });
  }

  Future<void> _save() async {
    final supervisorUid =
        _isAdmin ? _selectedSupervisor?.uid : widget.session.uid;
    if (supervisorUid == null || supervisorUid.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _assignmentService.setSupervisedLeaderIds(
        supervisorUid: supervisorUid,
        leaderIds: _selectedLeaderIds.toList()..sort(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asignaciones guardadas')),
      );
      if (_isAdmin) {
        await _loadInitialData();
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            SupervisorAssignmentService.messageFromFirestoreException(e),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<ChurchLeader> get _displayLeaders {
    if (!_isAdmin) return _leaders;
    final supervisorUid = _selectedSupervisor?.uid;
    if (supervisorUid == null) return [];
    return _assignableLeaders.where((leader) {
      final id = leader.id;
      if (id == null || id.isEmpty) return false;
      final owner = _leaderOwnerBySupervisorUid[id];
      return owner == null || owner == supervisorUid;
    }).toList();
  }

  List<ChurchLeader> get _filteredLeaders {
    final query = _searchController.text;
    return _displayLeaders.where((l) => leaderMatchesSearch(l, query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canViewSupervisorLeaderAssignments,
      deniedMessage:
          'Solo administradores y supervisores pueden ver esta sección.',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isAdmin ? 'Líderes por supervisor' : 'Mis líderes asignados',
          ),
        ),
        body: _buildBody(),
        floatingActionButton: _isAdmin && !_loading && _loadError == null
            ? FloatingActionButton.extended(
                onPressed: _saving ||
                        _selectedSupervisor == null ||
                        _supervisors.isEmpty
                    ? null
                    : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando…' : 'Guardar'),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadInitialData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAdmin && _supervisors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No hay usuarios con rol Supervisor.\n'
            'Registra un líder y asígnale el rol Supervisor.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    if (_displayLeaders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _isAdmin
                ? 'No hay líderes con rol Líder disponibles para este supervisor.\n'
                    'Los ya asignados a otro supervisor no se muestran.'
                : 'No tienes líderes asignados.\n'
                    'Pide al administrador que te asigne líderes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final filtered = _filteredLeaders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isAdmin) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<SupervisorAccount>(
              key: ValueKey(_selectedSupervisor?.uid),
              initialValue: _selectedSupervisor,
              decoration: const InputDecoration(
                labelText: 'Supervisor *',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                border: OutlineInputBorder(),
              ),
              items: _supervisors
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.displayLabel),
                    ),
                  )
                  .toList(),
              onChanged: _saving ? null : _onSupervisorChanged,
            ),
          ),
          const SizedBox(height: 8),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estos son los líderes que el administrador te asignó.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_isAdmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${_selectedLeaderIds.length} de ${_displayLeaders.length} '
              'líderes disponibles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${_leaders.length} ${_leaders.length == 1 ? 'líder asignado' : 'líderes asignados'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        PersonListSearchField(
          controller: _searchController,
          hintText: 'Buscar líder por nombre, célula o teléfono…',
          onChanged: (_) => setState(() {}),
        ),
        Expanded(
          child: filtered.isEmpty
              ? PersonListSearchEmptyState(query: _searchController.text)
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    _isAdmin ? 88 : 24,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final leader = filtered[index];
                    final id = leader.id;
                    if (id == null) return const SizedBox.shrink();

                    final parts = <String>[
                      if (leader.churchOfficeLabel != null)
                        leader.churchOfficeLabel!,
                      if (leader.cellCode != null) 'Célula ${leader.cellCode}',
                      leader.mobilePhone,
                    ];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: _selectedLeaderIds.contains(id),
                        onChanged: _isAdmin && !_saving
                            ? (checked) => _toggleLeader(id, checked ?? false)
                            : null,
                        title: Text(
                          '${leader.lastName}, ${leader.firstName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: parts.isNotEmpty ? Text(parts.join(' · ')) : null,
                        secondary: CircleAvatar(
                          child: Text(
                            leader.lastName.isNotEmpty
                                ? leader.lastName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
