import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/screens/account_hub_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/church_logo.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../../core/widgets/slide_menu_scaffold.dart';
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
      await _notificationService.syncAssignmentsForLeader(
        leaderId: leaderId,
        recipientUserId: widget.session.uid,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' && mounted) {
        debugPrint(
          'Notificaciones: permission-denied. Publica firestore.rules '
          '(ver FIREBASE_SETUP.md).',
        );
      }
    } catch (_) {
      // La pantalla de notificaciones mostrará el error si persiste.
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
      ),
      'Mis nuevos creyentes',
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
            RegisterMemberScreen(registeredBy: _email),
            'Nuevo creyente',
          ),
        ),
      );
    }

    if (p.canViewMembersList) {
      items.add(
        SlideMenuItem(
          icon: Icons.people_outlined,
          label: 'Nuevos creyentes',
          onTap: () => _navigate(
            MembersListScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'Nuevos creyentes',
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
          label: 'Mis nuevos creyentes',
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
          label: 'Ver líderes',
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

    if (p.canViewSupervisorLeaderAssignments) {
      items.add(
        SlideMenuItem(
          icon: Icons.assignment_ind_outlined,
          label: 'Líderes por supervisor',
          onTap: () => _navigate(
            SupervisorLeaderAssignmentsScreen(session: widget.session),
            'Líderes por supervisor',
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
        title: 'Registrar nuevo creyente',
        subtitle: 'Formulario de nuevo creyente',
        onTap: () => _navigate(
          RegisterMemberScreen(registeredBy: _email),
          'Nuevo creyente',
        ),
      );
    }
    if (p.canViewMembersList) {
      addEntry(
        icon: Icons.people_outlined,
        title: 'Ver nuevos creyentes',
        subtitle: 'Lista de nuevos creyentes registrados',
        onTap: () => _navigate(
          MembersListScreen(registeredBy: _email, permissions: p),
          'Nuevos creyentes',
        ),
      );
    }
    if (p.canViewMembersByLeader) {
      addEntry(
        icon: Icons.how_to_reg_outlined,
        title: 'Nuevos creyentes por líder',
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
        title: 'Mis nuevos creyentes asignados',
        subtitle: 'Nuevos creyentes bajo tu liderazgo',
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
    if (p.canViewSupervisorLeaderAssignments) {
      addEntry(
        icon: Icons.assignment_ind_outlined,
        title: 'Líderes por supervisor',
        subtitle: p.canAssignSupervisorLeaders
            ? 'Asignar líderes a cada supervisor'
            : 'Líderes que te fueron asignados',
        onTap: () => _navigate(
          SupervisorLeaderAssignmentsScreen(session: widget.session),
          'Líderes por supervisor',
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
    if (widget.session.profile.leaderId == null ||
        widget.session.profile.leaderId!.isEmpty) {
      return null;
    }

    return StreamBuilder<int>(
      stream: _notificationService.watchUnreadCountForUser(widget.session.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return IconButton(
            tooltip: 'Notificaciones (revisa reglas de Firestore)',
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: () => _navigate(
              LeaderNotificationsScreen(session: widget.session),
              'Notificaciones',
            ),
          );
        }
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
      title: appDisplayName,
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
                    child: ChurchLogo(size: 48),
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
