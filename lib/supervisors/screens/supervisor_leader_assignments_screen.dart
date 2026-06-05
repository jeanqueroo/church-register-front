import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/services/leader_service.dart';
import '../models/supervisor_account.dart';
import '../services/supervisor_assignment_service.dart';

/// Asigna líderes a usuarios con rol supervisor (admin) o consulta la propia cartera.
class SupervisorLeaderAssignmentsScreen extends StatefulWidget {
  const SupervisorLeaderAssignmentsScreen({
    super.key,
    required this.session,
    this.permissions,
    this.assignmentService,
    this.leaderService,
  });

  final UserSession session;
  final AppPermissions? permissions;
  final SupervisorAssignmentService? assignmentService;
  final LeaderService? leaderService;

  @override
  State<SupervisorLeaderAssignmentsScreen> createState() =>
      _SupervisorLeaderAssignmentsScreenState();
}

class _SupervisorLeaderAssignmentsScreenState
    extends State<SupervisorLeaderAssignmentsScreen> {
  late final SupervisorAssignmentService _assignmentService;
  late final LeaderService _leaderService;
  late final AppPermissions _permissions;

  final _leaderSearchController = TextEditingController();

  List<SupervisorAccount> _supervisors = [];
  List<ChurchLeader> _leaders = [];
  Set<String> _selectedLeaderIds = {};
  String? _selectedSupervisorUid;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  bool get _canAssign => _permissions.canAssignSupervisorLeaders;

  String? get _churchId => _permissions.churchId;

  @override
  void initState() {
    super.initState();
    _assignmentService =
        widget.assignmentService ?? SupervisorAssignmentService();
    _leaderService = widget.leaderService ?? LeaderService();
    _permissions = widget.permissions ?? widget.session.permissions;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _leaderSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final supervisors = await _assignmentService.fetchSupervisors(
        churchId: _churchId,
      );
      final leaders = await _leaderService.fetchAssignableLeaders(
        churchId: _churchId,
      );
      leaders.sort((a, b) => a.fullName.compareTo(b.fullName));

      if (!mounted) return;

      var supervisorList = supervisors;
      // Si el usuario actual también tiene rol supervisor, no debe aparecer
      // como opción seleccionable en la vista de asignación (evita auto-selección).
      if (_canAssign) {
        supervisorList =
            supervisorList.where((s) => s.uid != widget.session.uid).toList();
      }
      if (!_canAssign && _permissions.isSupervisor) {
        final inList =
            supervisorList.any((account) => account.uid == widget.session.uid);
        if (!inList) {
          supervisorList = [
            SupervisorAccount(
              uid: widget.session.uid,
              email: widget.session.email,
              leaderId: widget.session.profile.leaderId,
              churchId: widget.session.profile.churchId,
              displayName: widget.session.resolvedDisplayName,
              supervisedLeaderIds: const [],
            ),
            ...supervisorList,
          ];
        }
      }

      String? selectedUid;
      if (_canAssign) {
        selectedUid =
            supervisorList.isNotEmpty ? supervisorList.first.uid : null;
      } else if (_permissions.isSupervisor) {
        selectedUid = widget.session.uid;
      }

      if (selectedUid != null &&
          !supervisorList.any((supervisor) => supervisor.uid == selectedUid)) {
        selectedUid =
            supervisorList.isNotEmpty ? supervisorList.first.uid : null;
      }

      setState(() {
        _supervisors = supervisorList;
        _leaders = leaders;
        _selectedSupervisorUid = selectedUid;
        _loading = false;
      });

      if (selectedUid != null) {
        await _loadAssignmentsForSupervisor(selectedUid);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = SupervisorAssignmentService.messageFromException(e);
      });
    }
  }

  Future<void> _loadAssignmentsForSupervisor(String supervisorUid) async {
    try {
      final ids =
          await _assignmentService.fetchSupervisedLeaderIds(supervisorUid);
      if (!mounted) return;

      // Si el supervisor seleccionado también es líder (`leaderId`),
      // no debe aparecer como "líder asignado" en esta pantalla.
      String? supervisorOwnLeaderId = widget.session.profile.leaderId;
      if (supervisorUid != widget.session.uid) {
        final match = _supervisors.where((s) => s.uid == supervisorUid);
        if (match.isNotEmpty) {
          supervisorOwnLeaderId = match.first.leaderId;
        } else {
          supervisorOwnLeaderId = null;
        }
      }

      final idsSet = ids.toSet();

      final allowedIds = _leaders
          .map((l) => l.id)
          .whereType<String>()
          .toSet();
      final selected = idsSet.intersection(allowedIds);
      if (supervisorOwnLeaderId != null && supervisorOwnLeaderId.isNotEmpty) {
        selected.remove(supervisorOwnLeaderId);
      }

      setState(() => _selectedLeaderIds = selected);
    } catch (e) {
      if (!mounted) return;
      _showMessage(SupervisorAssignmentService.messageFromException(e));
    }
  }

  Future<void> _onSupervisorChanged(String? supervisorUid) async {
    if (supervisorUid == null) return;
    setState(() {
      _selectedSupervisorUid = supervisorUid;
      _selectedLeaderIds = {};
    });
    await _loadAssignmentsForSupervisor(supervisorUid);
  }

  SupervisorAccount? _supervisorOwningLeader(String leaderId) {
    final currentUid = _selectedSupervisorUid;
    for (final supervisor in _supervisors) {
      if (supervisor.uid == currentUid) continue;
      if (supervisor.supervisedLeaderIds.contains(leaderId)) {
        return supervisor;
      }
    }
    return null;
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
    final supervisorUid = _selectedSupervisorUid;
    if (supervisorUid == null) {
      _showMessage('Selecciona un supervisor');
      return;
    }

    for (final leaderId in _selectedLeaderIds) {
      final owner = _supervisorOwningLeader(leaderId);
      if (owner != null) {
        _showMessage(
          'No se puede guardar: un líder ya pertenece a '
          '${_supervisorSelectLabel(owner)}',
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await _assignmentService.saveSupervisedLeaders(
        supervisorUid: supervisorUid,
        leaderIds: _selectedLeaderIds.toList(),
      );
      if (!mounted) return;
      setState(() {
        _supervisors = _supervisors
            .map(
              (supervisor) => supervisor.uid == supervisorUid
                  ? supervisor.copyWith(
                      supervisedLeaderIds: _selectedLeaderIds.toList(),
                    )
                  : supervisor,
            )
            .toList();
      });
      _showMessage('Líderes asignados correctamente');
    } catch (e) {
      if (!mounted) return;
      _showMessage(SupervisorAssignmentService.messageFromException(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<ChurchLeader> get _filteredLeaders {
    final query = _leaderSearchController.text.trim().toLowerCase();
    var list = query.isEmpty ? _leaders : _leaders.where((leader) {
      final haystack = [
        leader.fullName,
        leader.firstName,
        leader.lastName,
        leader.cellCode,
        leader.locality,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    // Si el supervisor seleccionado también es líder (tiene `leaderId`),
    // no debe mostrarse como líder asignado.
    final hideLeaderId = _selectedSupervisorOwnLeaderId;
    if (hideLeaderId != null && hideLeaderId.isNotEmpty) {
      list = list.where((l) => l.id != hideLeaderId).toList();
    }

    // Líderes ya asignados a otro supervisor no se muestran.
    list = list.where((leader) {
      final id = leader.id;
      if (id == null || id.isEmpty) return false;
      return _supervisorOwningLeader(id) == null;
    }).toList();

    return list;
  }

  SupervisorAccount? get _selectedSupervisor {
    final uid = _selectedSupervisorUid;
    if (uid == null) return null;
    for (final supervisor in _supervisors) {
      if (supervisor.uid == uid) return supervisor;
    }
    return null;
  }

  String? get _selectedSupervisorOwnLeaderId {
    final selectedUid = _selectedSupervisorUid;
    if (selectedUid == null || selectedUid.isEmpty) return null;
    if (selectedUid == widget.session.uid) {
      return widget.session.profile.leaderId;
    }
    for (final supervisor in _supervisors) {
      if (supervisor.uid == selectedUid) return supervisor.leaderId;
    }
    return null;
  }

  String _supervisorSelectLabel(SupervisorAccount supervisor) {
    final name = supervisor.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return supervisor.email;
  }

  /// Valor válido del dropdown: debe existir en [_supervisors].
  String? get _effectiveSupervisorDropdownValue {
    final selected = _selectedSupervisorUid;
    if (selected != null &&
        _supervisors.any((supervisor) => supervisor.uid == selected)) {
      return selected;
    }
    if (_supervisors.isEmpty) return null;
    return _supervisors.first.uid;
  }

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canViewSupervisorLeaderAssignments,
      deniedMessage:
          'No tienes permiso para ver las asignaciones de líderes por supervisor.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Líderes por supervisor'),
        ),
        body: _buildBody(),
        floatingActionButton: _canAssign && !_loading && _loadError == null
            ? FloatingActionButton.extended(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar'),
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
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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

    if (_supervisors.isEmpty && !_permissions.isSupervisor) {
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
                'No hay supervisores en tu iglesia',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Al registrar un líder, asigna el rol Supervisor en la app.',
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (_canAssign) ...[
          Text(
            'Supervisor',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_effectiveSupervisorDropdownValue),
            initialValue: _effectiveSupervisorDropdownValue,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
              labelText: 'Selecciona supervisor *',
            ),
            items: _supervisors
                .map(
                  (supervisor) => DropdownMenuItem(
                    value: supervisor.uid,
                    child: Text(
                      _supervisorSelectLabel(supervisor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _saving ? null : _onSupervisorChanged,
          ),
        ] else ...[
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.supervisor_account_outlined),
              ),
              title: Text(_selectedSupervisor?.displayLabel ?? widget.session.email),
              subtitle: const Text('Tus líderes asignados'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Líderes asignados (${_selectedLeaderIds.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (!_canAssign)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Solo el administrador puede modificar estas asignaciones.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        TextField(
          controller: _leaderSearchController,
          enabled: !_saving && _canAssign,
          decoration: const InputDecoration(
            labelText: 'Buscar líder',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (_leaders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No hay líderes registrados en tu iglesia.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else if (_filteredLeaders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _leaderSearchController.text.trim().isNotEmpty
                  ? 'Ningún líder coincide con la búsqueda.'
                  : 'No hay líderes disponibles para asignar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ..._filteredLeaders.map((leader) {
            final id = leader.id;
            if (id == null) return const SizedBox.shrink();
            final selected = _selectedLeaderIds.contains(id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: selected,
                onChanged: _canAssign && !_saving
                    ? (value) => _toggleLeader(id, value ?? false)
                    : null,
                secondary: CircleAvatar(
                  child: Text(
                    leader.lastName.isNotEmpty
                        ? leader.lastName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(leader.fullName),
                subtitle: Text(
                  SupervisorAssignmentService.leaderLabel(leader),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }),
      ],
    );
  }
}
