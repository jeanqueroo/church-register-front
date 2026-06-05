import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/screens/account_hub_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/church_logo.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../../core/widgets/slide_menu_scaffold.dart';
import '../../auth/screens/admins_list_screen.dart';
import '../../auth/screens/register_admin_screen.dart';
import '../../church/screens/churches_list_screen.dart';
import '../../leaders/screens/leader_assigned_members_screen.dart';
import '../../leaders/screens/leaders_list_screen.dart';
import '../../leaders/screens/register_leader_screen.dart';
import '../../leaders/services/leader_service.dart';
import '../../members/screens/members_by_leader_screen.dart';
import '../../members/screens/members_list_screen.dart';
import '../../members/screens/register_member_screen.dart';
import '../../notifications/screens/leader_notifications_screen.dart';
import '../../notifications/services/leader_notification_service.dart';
import '../../supervisors/screens/supervisor_leader_assignments_screen.dart';
import '../../supervisors/screens/supervisor_my_leaders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.session,
    this.authService,
  });

  final UserSession session;
  final AuthService? authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _menuInicio = 'Inicio';

  String _selectedMenu = _menuInicio;
  final _leaderService = LeaderService();
  final _notificationService = LeaderNotificationService();

  AppPermissions get _permissions => widget.session.permissions;
  String get _email => widget.session.email;
  String? get _churchId => widget.session.profile.churchId;

  @override
  void initState() {
    super.initState();
    _syncLeaderNotifications();
  }

  Future<void> _syncLeaderNotifications() async {
    if (!_permissions.canViewLeaderNotifications) return;
    final leaderId = widget.session.profile.leaderId;
    if (leaderId == null || leaderId.isEmpty) return;
    try {
      await _notificationService.syncAssignmentsForLeader(leaderId);
    } catch (_) {
      // Si falla (p. ej. reglas), la pantalla de notificaciones mostrará el error.
    }
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

  Future<void> _openMyAssignedMembers() async {
    final leaderId = widget.session.profile.leaderId;
    if (leaderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu cuenta de líder no está vinculada a un registro.'),
        ),
      );
      return;
    }

    final leader = await _leaderService.fetchLeaderById(leaderId);
    if (!mounted) return;
    if (leader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró tu ficha de líder.')),
      );
      return;
    }

    _navigate(
      LeaderAssignedMembersScreen(
        leader: leader,
        registeredBy: _email,
        permissions: _permissions,
      ),
      'Mis integrantes',
    );
  }

  List<SlideMenuItem> _buildMenuItems() {
    final p = _permissions;
    final items = <SlideMenuItem>[
      SlideMenuItem(
        icon: Icons.home_outlined,
        label: _menuInicio,
        onTap: () => setState(() => _selectedMenu = _menuInicio),
      ),
    ];

    if (p.canRegisterMember) {
      items.add(
        SlideMenuItem(
          icon: Icons.person_add_outlined,
          label: 'Nuevo creyente',
          onTap: () => _navigate(
            RegisterMemberScreen(
              registeredBy: _email,
              churchId: _churchId,
              permissions: p,
            ),
            'Registro de nuevo creyente',
          ),
        ),
      );
    }

    if (p.canViewMembersList) {
      items.add(
        SlideMenuItem(
          icon: Icons.people_outlined,
          label: 'Integrantes',
          onTap: () => _navigate(
            MembersListScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'Integrantes',
          ),
        ),
      );
    }

    if (p.canViewMembersByLeader) {
      items.add(
        SlideMenuItem(
          icon: Icons.how_to_reg_outlined,
          label: 'Por líder',
          onTap: () => _navigate(
            MembersByLeaderScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'Por líder',
          ),
        ),
      );
    }

    if (p.canViewMyAssignedMembers) {
      items.add(
        SlideMenuItem(
          icon: Icons.group_outlined,
          label: 'Mis integrantes',
          onTap: _openMyAssignedMembers,
        ),
      );
    }

    if (p.canRegisterLeader) {
      items.add(
        SlideMenuItem(
          icon: Icons.supervisor_account_outlined,
          label: 'Nuevo líder',
          onTap: () => _navigate(
            RegisterLeaderScreen(
              registeredBy: _email,
              churchId: _churchId,
              permissions: p,
            ),
            'Nuevo líder',
          ),
        ),
      );
    }

    if (p.canViewLeadersList) {
      items.add(
        SlideMenuItem(
          icon: Icons.groups_outlined,
          label: 'Líderes',
          onTap: () => _navigate(
            LeadersListScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'Líderes',
          ),
        ),
      );
    }

    if (p.canViewMySupervisedLeaders) {
      items.add(
        SlideMenuItem(
          icon: Icons.account_tree_outlined,
          label: 'Mis líderes asignados',
          onTap: () => _navigate(
            SupervisorMyLeadersScreen(session: widget.session),
            'Mis líderes asignados',
          ),
        ),
      );
    }

    if (p.canAssignSupervisorLeaders) {
      items.add(
        SlideMenuItem(
          icon: Icons.manage_accounts_outlined,
          label: 'Líderes por supervisor',
          onTap: () => _navigate(
            SupervisorLeaderAssignmentsScreen(session: widget.session),
            'Líderes por supervisor',
          ),
        ),
      );
    }

    if (p.canViewChurchesList) {
      items.add(
        SlideMenuItem(
          icon: Icons.church_outlined,
          label: 'Iglesias',
          onTap: () => _navigate(
            ChurchesListScreen(
              updatedBy: _email,
              permissions: p,
            ),
            'Iglesias',
          ),
        ),
      );
    }

    if (p.canViewAdminsList) {
      items.add(
        SlideMenuItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Administradores',
          onTap: () => _navigate(
            AdminsListScreen(
              updatedBy: _email,
              permissions: p,
            ),
            'Administradores',
          ),
        ),
      );
    }

    if (p.canRegisterAdmin) {
      items.add(
        SlideMenuItem(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Nuevo administrador',
          onTap: () => _navigate(
            RegisterAdminScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'Nuevo administrador',
          ),
        ),
      );
    }

    return items;
  }

  List<Widget> _buildQuickAccessList() {
    final p = _permissions;
    final entries = <({IconData icon, String title, String subtitle, VoidCallback onTap})>[];

    void addEntry({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      entries.add((icon: icon, title: title, subtitle: subtitle, onTap: onTap));
    }

    if (p.canRegisterMember) {
      addEntry(
        icon: Icons.person_add_outlined,
        title: 'Registro de nuevo creyente',
        subtitle: 'Formulario de nuevo creyente',
        onTap: () => _navigate(
          RegisterMemberScreen(
            registeredBy: _email,
            churchId: _churchId,
            permissions: p,
          ),
          'Registro de nuevo creyente',
        ),
      );
    }
    if (p.canViewMembersList) {
      addEntry(
        icon: Icons.people_outlined,
        title: 'Ver creyentes',
        subtitle: 'Lista de integrantes registrados',
        onTap: () => _navigate(
          MembersListScreen(registeredBy: _email, permissions: p),
          'Integrantes',
        ),
      );
    }
    if (p.canViewMembersByLeader) {
      addEntry(
        icon: Icons.how_to_reg_outlined,
        title: 'Integrantes por líder',
        subtitle: 'Miembros asignados a cada líder',
        onTap: () => _navigate(
          MembersByLeaderScreen(registeredBy: _email, permissions: p),
          'Por líder',
        ),
      );
    }
    if (p.canViewMyAssignedMembers) {
      addEntry(
        icon: Icons.group_outlined,
        title: 'Mis integrantes asignados',
        subtitle: 'Integrantes bajo tu liderazgo',
        onTap: _openMyAssignedMembers,
      );
    }
    if (p.canRegisterLeader) {
      addEntry(
        icon: Icons.supervisor_account_outlined,
        title: 'Registrar líder',
        subtitle: 'Datos del liderazgo',
        onTap: () => _navigate(
          RegisterLeaderScreen(
            registeredBy: _email,
            churchId: _churchId,
            permissions: p,
          ),
          'Nuevo líder',
        ),
      );
    }
    if (p.canViewLeadersList) {
      addEntry(
        icon: Icons.groups_outlined,
        title: 'Ver líderes',
        subtitle: 'Lista de líderes registrados',
        onTap: () => _navigate(
          LeadersListScreen(registeredBy: _email, permissions: p),
          'Líderes',
        ),
      );
    }
    if (p.canViewMySupervisedLeaders) {
      addEntry(
        icon: Icons.account_tree_outlined,
        title: 'Mis líderes asignados',
        subtitle: 'Líderes bajo tu supervisión',
        onTap: () => _navigate(
          SupervisorMyLeadersScreen(session: widget.session),
          'Mis líderes asignados',
        ),
      );
    }
    if (p.canAssignSupervisorLeaders) {
      addEntry(
        icon: Icons.manage_accounts_outlined,
        title: 'Líderes por supervisor',
        subtitle: 'Asignar cartera de líderes a cada supervisor',
        onTap: () => _navigate(
          SupervisorLeaderAssignmentsScreen(session: widget.session),
          'Líderes por supervisor',
        ),
      );
    }
    if (p.canViewChurchesList) {
      addEntry(
        icon: Icons.church_outlined,
        title: 'Iglesias',
        subtitle: 'Ver, editar y registrar sedes',
        onTap: () => _navigate(
          ChurchesListScreen(
            updatedBy: _email,
            permissions: p,
          ),
          'Iglesias',
        ),
      );
    }
    if (p.canViewAdminsList) {
      addEntry(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Administradores',
        subtitle: 'Ver, editar y bloquear cuentas',
        onTap: () => _navigate(
          AdminsListScreen(
            updatedBy: _email,
            permissions: p,
          ),
          'Administradores',
        ),
      );
    }
    if (p.canRegisterAdmin) {
      addEntry(
        icon: Icons.person_add_alt_1_outlined,
        title: 'Nuevo administrador',
        subtitle: 'Asignar iglesia al administrador',
        onTap: () => _navigate(
          RegisterAdminScreen(
            registeredBy: _email,
            permissions: p,
          ),
          'Nuevo administrador',
        ),
      );
    }

    return [
      for (var i = 0; i < entries.length; i++)
        WhatsappListTile(
          icon: entries[i].icon,
          title: entries[i].title,
          subtitle: entries[i].subtitle,
          onTap: entries[i].onTap,
          showDivider: i < entries.length - 1,
        ),
    ];
  }

  Widget? _buildNotificationsAction() {
    if (!_permissions.canViewLeaderNotifications) return null;
    final leaderId = widget.session.profile.leaderId;
    if (leaderId == null || leaderId.isEmpty) return null;

    return StreamBuilder<int>(
      stream: _notificationService.watchUnreadCountForLeader(leaderId),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            tooltip: 'Notificaciones',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => _navigate(
              LeaderNotificationsScreen(session: widget.session),
              'Notificaciones',
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountActionButton() {
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

  @override
  Widget build(BuildContext context) {
    return SlideMenuScaffold(
      churchId: widget.session.profile.churchId,
      selectedMenuLabel: _selectedMenu,
      onSignOut: _logout,
      actions: [
        ?(_buildNotificationsAction()),
        _buildAccountActionButton(),
      ],
      menuItems: _buildMenuItems(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: ClipOval(
                    child: ChurchLogo(
                      size: 48,
                      churchId: widget.session.profile.churchId,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.resolvedDisplayName.isNotEmpty
                            ? widget.session.resolvedDisplayName
                            : 'Bienvenido',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111B21),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (widget.session.profile.permissions.roleLabels
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: widget
                              .session.profile.permissions.roleLabels
                              .map((label) => Chip(label: Text(label)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _buildQuickAccessList().isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No hay accesos disponibles para tu rol. '
                        'Contacta al administrador.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  )
                : ListView(
                    children: _buildQuickAccessList(),
                  ),
          ),
        ],
      ),
    );
  }
}
