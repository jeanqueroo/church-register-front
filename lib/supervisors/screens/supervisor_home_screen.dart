import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/screens/account_hub_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../core/services/excel_export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/list_search.dart';
import '../../core/widgets/export_excel_icon_button.dart';
import '../../core/widgets/person_list_search_field.dart';
import '../../core/widgets/slide_menu_scaffold.dart';
import '../../leaders/models/church_leader.dart';
import '../../leaders/screens/leader_assigned_members_screen.dart';
import '../../leaders/screens/register_leader_screen.dart';
import '../../leaders/services/leader_service.dart';
import '../../leaders/widgets/leaders_map_view.dart';
import '../../members/screens/register_member_screen.dart';
import '../services/supervisor_assignment_service.dart';
import '../utils/supervisor_members_filter.dart';

/// Inicio del supervisor: sus líderes asignados en lista y mapa.
class SupervisorHomeScreen extends StatefulWidget {
  const SupervisorHomeScreen({
    super.key,
    required this.session,
    this.authService,
    this.leaderService,
    this.assignmentService,
  });

  final UserSession session;
  final AuthService? authService;
  final LeaderService? leaderService;
  final SupervisorAssignmentService? assignmentService;

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _menuInicio = 'Mis líderes';

  late final TabController _tabController;
  final _searchController = TextEditingController();
  late final LeaderService _leaderService;
  late final SupervisorAssignmentService _assignmentService;

  String _selectedMenu = _menuInicio;
  List<ChurchLeader> _leadersForExport = [];
  bool _canExport = false;

  AppPermissions get _permissions => widget.session.permissions;
  String get _email => widget.session.email;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _leaderService = widget.leaderService ?? LeaderService();
    _assignmentService =
        widget.assignmentService ?? SupervisorAssignmentService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final auth = widget.authService ?? AuthService();
    await auth.signOut();
  }

  void _navigate(Widget screen, String menuLabel) {
    setState(() => _selectedMenu = menuLabel);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _syncLeadersForExport(List<ChurchLeader> leaders) {
    _leadersForExport = leaders;
    final canExport = leaders.isNotEmpty;
    if (canExport == _canExport) return;
    _canExport = canExport;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _exportToExcel() {
    return ExcelExportService.instance.shareLeadersExcel(
      leaders: _leadersForExport,
      fileName: 'mis_lideres_${DateTime.now().millisecondsSinceEpoch}',
      sheetTitle: 'Mis líderes',
    );
  }

  void _openLeaderCreyentes(ChurchLeader leader) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeaderAssignedMembersScreen(
          leader: leader,
          registeredBy: _email,
          permissions: _permissions,
        ),
      ),
    );
  }

  List<SlideMenuItem> _buildMenuItems() {
    final p = _permissions;
    return [
      SlideMenuItem(
        icon: Icons.home_outlined,
        label: _menuInicio,
        onTap: () => setState(() => _selectedMenu = _menuInicio),
      ),
      if (p.canRegisterMember)
        SlideMenuItem(
          icon: Icons.person_add_outlined,
          label: 'Nuevo creyente',
          onTap: () => _navigate(
            RegisterMemberScreen(
              registeredBy: _email,
              supervisorUid: widget.session.uid,
            ),
            'Nuevo creyente',
          ),
        ),
      if (p.canRegisterLeader)
        SlideMenuItem(
          icon: Icons.supervisor_account_outlined,
          label: 'Registrar líder',
          onTap: () => _navigate(
            RegisterLeaderScreen(registeredBy: _email),
            'Registrar líder',
          ),
        ),
    ];
  }

  Widget _buildAccountAction() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Mi cuenta',
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.person, color: Colors.white, size: 22),
            onPressed: () => _navigate(
              AccountHubScreen(session: widget.session),
              'Mi cuenta',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int leaderCount) {
    final name = widget.session.resolvedDisplayName.isNotEmpty
        ? widget.session.resolvedDisplayName
        : 'Supervisor';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                leaderCount == 0
                    ? 'Aún no tienes líderes asignados.'
                    : '$leaderCount ${leaderCount == 1 ? 'líder asignado' : 'líderes asignados'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoLeadersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin líderes asignados',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Un administrador debe asignarte líderes. '
              'Luego los verás aquí en lista y en el mapa.',
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

  Widget _buildListTab(List<ChurchLeader> leaders, String query) {
    final filtered =
        leaders.where((l) => leaderMatchesSearch(l, query)).toList();
    if (filtered.isEmpty) {
      return PersonListSearchEmptyState(query: query);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final leader = filtered[index];
        final parts = <String>[
          if (leader.churchOfficeLabel != null) leader.churchOfficeLabel!,
          if (leader.cellCode != null) 'Célula ${leader.cellCode}',
          leader.mobilePhone,
          if (leader.geoLocation == null) 'Sin ubicación en mapa',
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openLeaderCreyentes(leader),
          ),
        );
      },
    );
  }

  Widget _buildDashboardBody() {
    return StreamBuilder<List<String>>(
      stream: _assignmentService.watchSupervisedLeaderIds(widget.session.uid),
      builder: (context, leaderIdsSnapshot) {
        if (leaderIdsSnapshot.connectionState == ConnectionState.waiting &&
            !leaderIdsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (leaderIdsSnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar tus líderes asignados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        final leaderIds = leaderIdsSnapshot.data?.toSet() ?? {};
        if (leaderIds.isEmpty) {
          return _buildNoLeadersState();
        }

        return StreamBuilder<List<ChurchLeader>>(
          stream: _leaderService.watchLeaders(),
          builder: (context, leadersSnapshot) {
            if (leadersSnapshot.connectionState == ConnectionState.waiting &&
                !leadersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (leadersSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No se pudo cargar los líderes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              );
            }

            final assigned = leadersForSupervisor(
              leaderIds,
              leadersSnapshot.data ?? [],
            );
            _syncLeadersForExport(assigned);

            final query = _searchController.text;
            final filteredForMap = assigned
                .where((l) => leaderMatchesSearch(l, query))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(assigned.length),
                if (assigned.isNotEmpty)
                  PersonListSearchField(
                    controller: _searchController,
                    hintText: 'Buscar líder por nombre, célula o teléfono…',
                    onChanged: (_) => setState(() {}),
                  ),
                Expanded(
                  child: assigned.isEmpty
                      ? _buildNoLeadersState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildListTab(assigned, query),
                            LeadersMapView(
                              leaders: filteredForMap,
                              onLeaderTap: _openLeaderCreyentes,
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideMenuScaffold(
      title: appDisplayName,
      selectedMenuLabel: _selectedMenu,
      onSignOut: _logout,
      menuItems: _buildMenuItems(),
      actions: [
        ExportExcelIconButton(
          enabled: _canExport,
          onExport: _exportToExcel,
        ),
        _buildAccountAction(),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.list_outlined), text: 'Lista'),
                Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
              ],
            ),
          ),
          Expanded(child: _buildDashboardBody()),
        ],
      ),
    );
  }
}
