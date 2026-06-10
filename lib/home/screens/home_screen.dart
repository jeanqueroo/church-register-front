import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/screens/account_hub_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/locale/l10n_extensions.dart';
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
import '../../dashboard/screens/pastoral_dashboard_screen.dart';
import '../../dashboard/screens/visits_dashboard_screen.dart';

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
  static const _menuHome = 'home';

  String _selectedMenuId = _menuHome;
  final _leaderService = LeaderService();
  final _notificationService = LeaderNotificationService();

  AppPermissions get _permissions => widget.session.permissions;
  String get _email => widget.session.email;
  String? get _churchId =>
      widget.session.profile.churchId?.trim().isNotEmpty == true
          ? widget.session.profile.churchId
          : null;

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

  void _navigate(Widget screen, String menuId) {
    setState(() => _selectedMenuId = menuId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _openMyAssignedMembers() async {
    final l10n = context.l10n;
    final leaderId = widget.session.profile.leaderId;
    if (leaderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.leaderAccountNotLinked)),
      );
      return;
    }

    final leader = await _leaderService.fetchLeaderById(leaderId);
    if (!mounted) return;
    if (leader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.leaderRecordNotFound)),
      );
      return;
    }

    _navigate(
      LeaderAssignedMembersScreen(
        leader: leader,
        registeredBy: _email,
        permissions: _permissions,
      ),
      'myMembers',
    );
  }

  List<SlideMenuItem> _buildMenuItems(AppLocalizations l10n) {
    final p = _permissions;
    final items = <SlideMenuItem>[
      SlideMenuItem(
        id: _menuHome,
        icon: Icons.home_outlined,
        label: l10n.menuHome,
        onTap: () => setState(() => _selectedMenuId = _menuHome),
      ),
    ];

    if (p.canRegisterMember) {
      items.add(
        SlideMenuItem(
          id: 'newMember',
          icon: Icons.person_add_outlined,
          label: l10n.menuNewMember,
          onTap: () => _navigate(
            RegisterMemberScreen(
              registeredBy: _email,
              churchId: _churchId,
              permissions: p,
            ),
            'newMember',
          ),
        ),
      );
    }

    if (p.canViewMembersList) {
      items.add(
        SlideMenuItem(
          id: 'members',
          icon: Icons.people_outlined,
          label: l10n.menuMembers,
          onTap: () => _navigate(
            MembersListScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'members',
          ),
        ),
      );
    }

    if (p.canViewMembersByLeader) {
      items.add(
        SlideMenuItem(
          id: 'byLeader',
          icon: Icons.how_to_reg_outlined,
          label: l10n.menuByLeader,
          onTap: () => _navigate(
            MembersByLeaderScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'byLeader',
          ),
        ),
      );
    }

    if (p.canViewMyAssignedMembers) {
      items.add(
        SlideMenuItem(
          id: 'myMembers',
          icon: Icons.group_outlined,
          label: l10n.menuMyMembers,
          onTap: _openMyAssignedMembers,
        ),
      );
    }

    if (p.canRegisterLeader) {
      items.add(
        SlideMenuItem(
          id: 'newLeader',
          icon: Icons.supervisor_account_outlined,
          label: l10n.menuNewLeader,
          onTap: () => _navigate(
            RegisterLeaderScreen(
              registeredBy: _email,
              churchId: _churchId,
              permissions: p,
            ),
            'newLeader',
          ),
        ),
      );
    }

    if (p.canViewLeadersList) {
      items.add(
        SlideMenuItem(
          id: 'leaders',
          icon: Icons.groups_outlined,
          label: l10n.menuLeaders,
          onTap: () => _navigate(
            LeadersListScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'leaders',
          ),
        ),
      );
    }

    if (p.canViewMySupervisedLeaders) {
      items.add(
        SlideMenuItem(
          id: 'mySupervisedLeaders',
          icon: Icons.account_tree_outlined,
          label: l10n.menuMySupervisedLeaders,
          onTap: () => _navigate(
            SupervisorMyLeadersScreen(session: widget.session),
            'mySupervisedLeaders',
          ),
        ),
      );
    }

    if (p.canViewVisitsDashboard) {
      items.add(
        SlideMenuItem(
          id: 'visitsDashboard',
          icon: Icons.bar_chart_outlined,
          label: l10n.menuVisitsDashboard,
          onTap: () => _navigate(
            VisitsDashboardScreen(session: widget.session),
            'visitsDashboard',
          ),
        ),
      );
    }

    if (p.canViewPastoralDashboard) {
      items.add(
        SlideMenuItem(
          id: 'pastoralDashboard',
          icon: Icons.favorite_outline,
          label: l10n.menuPastoralDashboard,
          onTap: () => _navigate(
            PastoralDashboardScreen(session: widget.session),
            'pastoralDashboard',
          ),
        ),
      );
    }

    if (p.canAssignSupervisorLeaders) {
      items.add(
        SlideMenuItem(
          id: 'supervisorLeaders',
          icon: Icons.manage_accounts_outlined,
          label: l10n.menuSupervisorLeaders,
          onTap: () => _navigate(
            SupervisorLeaderAssignmentsScreen(session: widget.session),
            'supervisorLeaders',
          ),
        ),
      );
    }

    if (p.canViewChurchesList) {
      items.add(
        SlideMenuItem(
          id: 'churches',
          icon: Icons.church_outlined,
          label: l10n.menuChurches,
          onTap: () => _navigate(
            ChurchesListScreen(
              updatedBy: _email,
              permissions: p,
            ),
            'churches',
          ),
        ),
      );
    }

    if (p.canViewAdminsList) {
      items.add(
        SlideMenuItem(
          id: 'admins',
          icon: Icons.admin_panel_settings_outlined,
          label: l10n.menuAdmins,
          onTap: () => _navigate(
            AdminsListScreen(
              updatedBy: _email,
              permissions: p,
            ),
            'admins',
          ),
        ),
      );
    }

    if (p.canRegisterAdmin) {
      items.add(
        SlideMenuItem(
          id: 'newAdmin',
          icon: Icons.person_add_alt_1_outlined,
          label: l10n.menuNewAdmin,
          onTap: () => _navigate(
            RegisterAdminScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'newAdmin',
          ),
        ),
      );
    }

    return items;
  }

  List<Widget> _buildQuickAccessList(AppLocalizations l10n) {
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
        title: l10n.quickNewMemberTitle,
        subtitle: l10n.quickNewMemberSubtitle,
        onTap: () => _navigate(
          RegisterMemberScreen(
            registeredBy: _email,
            churchId: _churchId,
            permissions: p,
          ),
          'newMember',
        ),
      );
    }
    if (p.canViewMembersList) {
      addEntry(
        icon: Icons.people_outlined,
        title: l10n.quickViewMembersTitle,
        subtitle: l10n.quickViewMembersSubtitle,
        onTap: () => _navigate(
          MembersListScreen(registeredBy: _email, permissions: p),
          'members',
        ),
      );
    }
    if (p.canViewMembersByLeader) {
      addEntry(
        icon: Icons.how_to_reg_outlined,
        title: l10n.quickMembersByLeaderTitle,
        subtitle: l10n.quickMembersByLeaderSubtitle,
        onTap: () => _navigate(
          MembersByLeaderScreen(registeredBy: _email, permissions: p),
          'byLeader',
        ),
      );
    }
    if (p.canViewMyAssignedMembers) {
      addEntry(
        icon: Icons.group_outlined,
        title: l10n.quickMyMembersTitle,
        subtitle: l10n.quickMyMembersSubtitle,
        onTap: _openMyAssignedMembers,
      );
    }
    if (p.canRegisterLeader) {
      addEntry(
        icon: Icons.supervisor_account_outlined,
        title: l10n.quickRegisterLeaderTitle,
        subtitle: l10n.quickRegisterLeaderSubtitle,
        onTap: () => _navigate(
          RegisterLeaderScreen(
            registeredBy: _email,
            churchId: _churchId,
            permissions: p,
          ),
          'newLeader',
        ),
      );
    }
    if (p.canViewLeadersList) {
      addEntry(
        icon: Icons.groups_outlined,
        title: l10n.quickViewLeadersTitle,
        subtitle: l10n.quickViewLeadersSubtitle,
        onTap: () => _navigate(
          LeadersListScreen(registeredBy: _email, permissions: p),
          'leaders',
        ),
      );
    }
    if (p.canViewMySupervisedLeaders) {
      addEntry(
        icon: Icons.account_tree_outlined,
        title: l10n.quickMySupervisedLeadersTitle,
        subtitle: l10n.quickMySupervisedLeadersSubtitle,
        onTap: () => _navigate(
          SupervisorMyLeadersScreen(session: widget.session),
          'mySupervisedLeaders',
        ),
      );
    }
    if (p.canViewVisitsDashboard) {
      addEntry(
        icon: Icons.bar_chart_outlined,
        title: l10n.quickVisitsDashboardTitle,
        subtitle: l10n.quickVisitsDashboardSubtitle,
        onTap: () => _navigate(
          VisitsDashboardScreen(session: widget.session),
          'visitsDashboard',
        ),
      );
    }
    if (p.canViewPastoralDashboard) {
      addEntry(
        icon: Icons.favorite_outline,
        title: l10n.quickPastoralDashboardTitle,
        subtitle: l10n.quickPastoralDashboardSubtitle,
        onTap: () => _navigate(
          PastoralDashboardScreen(session: widget.session),
          'pastoralDashboard',
        ),
      );
    }
    if (p.canAssignSupervisorLeaders) {
      addEntry(
        icon: Icons.manage_accounts_outlined,
        title: l10n.quickSupervisorLeadersTitle,
        subtitle: l10n.quickSupervisorLeadersSubtitle,
        onTap: () => _navigate(
          SupervisorLeaderAssignmentsScreen(session: widget.session),
          'supervisorLeaders',
        ),
      );
    }
    if (p.canViewChurchesList) {
      addEntry(
        icon: Icons.church_outlined,
        title: l10n.quickChurchesTitle,
        subtitle: l10n.quickChurchesSubtitle,
        onTap: () => _navigate(
          ChurchesListScreen(
            updatedBy: _email,
            permissions: p,
          ),
          'churches',
        ),
      );
    }
    if (p.canViewAdminsList) {
      addEntry(
        icon: Icons.admin_panel_settings_outlined,
        title: l10n.quickAdminsTitle,
        subtitle: l10n.quickAdminsSubtitle,
        onTap: () => _navigate(
          AdminsListScreen(
            updatedBy: _email,
            permissions: p,
          ),
          'admins',
        ),
      );
    }
    if (p.canRegisterAdmin) {
      addEntry(
        icon: Icons.person_add_alt_1_outlined,
        title: l10n.quickNewAdminTitle,
        subtitle: l10n.quickNewAdminSubtitle,
        onTap: () => _navigate(
          RegisterAdminScreen(
            registeredBy: _email,
            permissions: p,
          ),
          'newAdmin',
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

  Widget? _buildNotificationsAction(AppLocalizations l10n) {
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
            tooltip: l10n.menuNotifications,
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 9 ? '9+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => _navigate(
              LeaderNotificationsScreen(session: widget.session),
              'notifications',
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountActionButton(AppLocalizations l10n) {
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
            tooltip: l10n.menuMyAccount,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.person, color: Colors.white, size: 22),
            onPressed: () => _navigate(
              AccountHubScreen(session: widget.session),
              'myAccount',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roleLabels =
        widget.session.profile.permissions.roleLabelsFor(l10n);

    return SlideMenuScaffold(
      churchId: widget.session.profile.churchId,
      selectedMenuId: _selectedMenuId,
      onSignOut: _logout,
      actions: [
        ?(_buildNotificationsAction(l10n)),
        _buildAccountActionButton(l10n),
      ],
      menuItems: _buildMenuItems(l10n),
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
                            : l10n.welcome,
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
                      if (roleLabels.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: roleLabels
                              .map(
                                (label) => Chip(
                                  label: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                ),
                              )
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
            child: _buildQuickAccessList(l10n).isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.noAccessForRole,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  )
                : ListView(
                    children: _buildQuickAccessList(l10n),
                  ),
          ),
        ],
      ),
    );
  }
}
