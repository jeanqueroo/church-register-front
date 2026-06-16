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
import '../../notifications/screens/admin_notifications_screen.dart';
import '../../notifications/screens/leader_notifications_screen.dart';
import '../../notifications/services/admin_notification_service.dart';
import '../../notifications/services/leader_notification_service.dart';
import '../../supervisors/screens/supervisor_leader_assignments_screen.dart';
import '../../supervisors/screens/supervisor_my_leaders_screen.dart';
import '../../baptism/screens/baptism_calendar_screen.dart';
import '../../cells/screens/cell_absence_by_leader_screen.dart';
import '../../cells/screens/cells_list_screen.dart';
import '../../cells/screens/cells_over_capacity_screen.dart';
import '../../cells/screens/my_assigned_cells_screen.dart';
import '../../cells/screens/register_cell_screen.dart';
import '../../dashboard/screens/pastoral_dashboard_screen.dart';
import '../../dashboard/screens/visits_dashboard_screen.dart';
import '../home_role_layout.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_dashboard_service.dart';
import '../widgets/role_home_body.dart';

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
  final _adminNotificationService = AdminNotificationService();
  final _dashboardService = HomeDashboardService();
  HomeDashboardData? _adminDashboard;
  bool _loadingAdminDashboard = false;
  String? _adminDashboardError;

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
    _loadAdminDashboard();
  }

  Future<void> _loadAdminDashboard({bool forceRefresh = false}) async {
    if (!_permissions.isAdmin || _churchId == null) return;

    setState(() {
      if (_adminDashboard == null) {
        _loadingAdminDashboard = true;
      }
      _adminDashboardError = null;
    });

    try {
      final data = await _dashboardService.loadForSession(
        widget.session,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _adminDashboard = data;
        _loadingAdminDashboard = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _adminDashboardError = error.toString();
        _loadingAdminDashboard = false;
      });
    }
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

  List<SlideMenuItem> _buildRegistrationMenuItems(AppPermissions p, AppLocalizations l10n) {
    final items = <SlideMenuItem>[];

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

    return items;
  }

  List<SlideMenuItem> _buildBaptismMenuItems(AppPermissions p, AppLocalizations l10n) {
    final items = <SlideMenuItem>[];

    if (p.canViewBaptismCalendar) {
      items.add(
        SlideMenuItem(
          id: 'baptismCalendar',
          icon: Icons.calendar_month_outlined,
          label: l10n.menuBaptismCalendar,
          onTap: () => _navigate(
            BaptismCalendarScreen(
              registeredBy: _email,
              churchId: _churchId,
              actingLeaderId: widget.session.profile.leaderId,
              permissions: p,
            ),
            'baptismCalendar',
          ),
        ),
      );
    }

    return items;
  }

  List<SlideMenuItem> _buildCellMenuItems(AppPermissions p, AppLocalizations l10n) {
    final items = <SlideMenuItem>[];

    if (p.canViewMyAssignedCell) {
      items.add(
        SlideMenuItem(
          id: 'myAssignedCell',
          icon: Icons.groups_2_outlined,
          label: l10n.menuMyAssignedCell,
          onTap: () => _navigate(
            MyAssignedCellsScreen(
              session: widget.session,
              registeredBy: _email,
            ),
            'myAssignedCell',
          ),
        ),
      );
      items.add(
        SlideMenuItem(
          id: 'registerCellAttendance',
          icon: Icons.event_available_outlined,
          label: l10n.cellAttendanceRegisterTitle,
          onTap: () => _navigate(
            MyAssignedCellsScreen(
              session: widget.session,
              registeredBy: _email,
              mode: MyAssignedCellsMode.attendance,
            ),
            'registerCellAttendance',
          ),
        ),
      );
      if (!p.canViewCells) {
        items.add(
          SlideMenuItem(
            id: 'cellAttendanceReport',
            icon: Icons.fact_check_outlined,
            label: l10n.menuViewCellAttendanceReport,
            onTap: () => _navigate(
              MyAssignedCellsScreen(
                session: widget.session,
                registeredBy: _email,
                mode: MyAssignedCellsMode.attendanceReport,
              ),
              'cellAttendanceReport',
            ),
          ),
        );
      }
      if (p.canViewCellAttendanceSessionsMenu) {
        items.add(
          SlideMenuItem(
            id: 'cellAttendanceSessions',
            icon: Icons.history_outlined,
            label: l10n.menuCellAttendanceSessions,
            onTap: () => _navigate(
              MyAssignedCellsScreen(
                session: widget.session,
                registeredBy: _email,
                mode: MyAssignedCellsMode.attendanceManage,
              ),
              'cellAttendanceSessions',
            ),
          ),
        );
      }
    }

    if (p.canViewCells) {
      items.add(
        SlideMenuItem(
          id: 'cellsList',
          icon: Icons.list_alt_outlined,
          label: l10n.menuViewCells,
          onTap: () => _navigate(
            CellsListScreen(
              registeredBy: _email,
              permissions: p,
            ),
            'cellsList',
          ),
        ),
      );
      items.add(
        SlideMenuItem(
          id: 'cellAttendanceReport',
          icon: Icons.fact_check_outlined,
          label: l10n.menuViewCellAttendanceReport,
          onTap: () => _navigate(
            CellsListScreen(
              registeredBy: _email,
              permissions: p,
              mode: CellsListMode.attendanceReport,
            ),
            'cellAttendanceReport',
          ),
        ),
      );
      if (p.canViewCellAbsenceByLeader) {
        items.add(
          SlideMenuItem(
            id: 'cellAbsenceByLeader',
            icon: Icons.warning_amber_outlined,
            label: l10n.menuCellAbsenceByLeader,
            onTap: () => _navigate(
              CellAbsenceByLeaderScreen(
                churchId: _churchId,
                permissions: p,
              ),
              'cellAbsenceByLeader',
            ),
          ),
        );
      }
      if (p.canRegisterCell) {
        items.add(
          SlideMenuItem(
            id: 'cellsOverCapacity',
            icon: Icons.call_split_outlined,
            label: l10n.menuCellsOverCapacity,
            onTap: () => _navigate(
              CellsOverCapacityScreen(
                registeredBy: _email,
                churchId: _churchId,
                permissions: p,
              ),
              'cellsOverCapacity',
            ),
          ),
        );
      }
    }

    if (p.canRegisterCell) {
      items.add(
        SlideMenuItem(
          id: 'newCell',
          icon: Icons.add_circle_outline,
          label: l10n.menuNewCell,
          onTap: () => _navigate(
            RegisterCellScreen(
              registeredBy: _email,
              churchId: _churchId,
              permissions: p,
            ),
            'newCell',
          ),
        ),
      );
    }

    return items;
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

    final registrationItems = _buildRegistrationMenuItems(p, l10n);
    if (registrationItems.isNotEmpty) {
      items.add(
        SlideMenuItem(
          id: 'registration',
          icon: Icons.app_registration_outlined,
          label: l10n.menuRegistration,
          children: registrationItems,
        ),
      );
    }

    final cellItems = _buildCellMenuItems(p, l10n);
    if (cellItems.isNotEmpty) {
      items.add(
        SlideMenuItem(
          id: 'cellGroup',
          icon: Icons.groups_2_outlined,
          label: l10n.menuCellGroup,
          children: cellItems,
        ),
      );
    }

    final baptismItems = _buildBaptismMenuItems(p, l10n);
    if (baptismItems.isNotEmpty) {
      items.add(
        SlideMenuItem(
          id: 'baptismGroup',
          icon: Icons.water_outlined,
          label: l10n.menuBaptismGroup,
          children: baptismItems,
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
    if (p.canViewMyAssignedCell) {
      addEntry(
        icon: Icons.groups_2_outlined,
        title: l10n.quickMyAssignedCellTitle,
        subtitle: l10n.quickMyAssignedCellSubtitle,
        onTap: () => _navigate(
          MyAssignedCellsScreen(
            session: widget.session,
            registeredBy: _email,
          ),
          'myAssignedCell',
        ),
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
    if (p.canRegisterCell) {
      addEntry(
        icon: Icons.groups_2_outlined,
        title: l10n.quickNewCellTitle,
        subtitle: l10n.quickNewCellSubtitle,
        onTap: () => _navigate(
          RegisterCellScreen(
            registeredBy: _email,
            churchId: _churchId,
            permissions: p,
          ),
          'newCell',
        ),
      );
    }
    if (p.canViewBaptismCalendar) {
      addEntry(
        icon: Icons.water_outlined,
        title: l10n.quickBaptismCalendarTitle,
        subtitle: l10n.quickBaptismCalendarSubtitle,
        onTap: () => _navigate(
          BaptismCalendarScreen(
            registeredBy: _email,
            churchId: _churchId,
            actingLeaderId: widget.session.profile.leaderId,
            permissions: p,
          ),
          'baptismCalendar',
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

  Widget? _buildAdminSummarySection(AppLocalizations l10n) {
    if (!_permissions.isAdmin || _churchId == null) return null;

    if (_loadingAdminDashboard) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_adminDashboardError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.homeDashboardLoadError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
    }

    final data = _adminDashboard;
    if (data == null) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.homeSummaryTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111B21),
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeSummaryMembersCount(data.memberCount),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.homeSummaryNewBelieversCount(data.newBelieverCount),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (data.leaderCount != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeSummaryLeadersCount(data.leaderCount!),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget? _buildNotificationsAction(AppLocalizations l10n) {
    if (_permissions.canViewChurchNotifications) {
      final uid = widget.session.uid;
      return StreamBuilder<int>(
        stream: _adminNotificationService.watchUnreadCountForUser(uid),
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: l10n.menuAdminNotifications,
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text(unread > 9 ? '9+' : '$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => _navigate(
                AdminNotificationsScreen(session: widget.session),
                'adminNotifications',
              ),
            ),
          );
        },
      );
    }

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
    final layout = resolveHomeRoleLayout(_permissions);
    final displayName = widget.session.resolvedDisplayName;
    final welcomeName = displayName.isNotEmpty ? displayName : _email;
    final isAdminHome = layout == HomeRoleLayout.admin ||
        layout == HomeRoleLayout.superAdmin;
    final quickAccess = _buildQuickAccessList(l10n);
    final adminSummary = _buildAdminSummarySection(l10n);

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
                  child: Text(
                    l10n.homeWelcomeName(welcomeName),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111B21),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: isAdminHome
                ? (quickAccess.isEmpty && adminSummary == null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.noAccessForRole,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          ?adminSummary,
                          if (quickAccess.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                l10n.homeQuickActionsTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111B21),
                                    ),
                              ),
                            ),
                            ...quickAccess,
                          ],
                        ],
                      )
                : RoleHomeBody(
                    session: widget.session,
                    layout: layout,
                    onNavigate: _navigate,
                  ),
          ),
        ],
      ),
    );
  }
}
