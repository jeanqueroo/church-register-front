import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../cells/screens/my_assigned_cells_screen.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../members/screens/register_member_screen.dart';
import '../home_role_layout.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_dashboard_service.dart';

class RoleHomeBody extends StatefulWidget {
  const RoleHomeBody({
    super.key,
    required this.session,
    required this.layout,
    required this.onNavigate,
    this.dashboardService,
  });

  final UserSession session;
  final HomeRoleLayout layout;
  final void Function(Widget screen, String menuId) onNavigate;
  final HomeDashboardService? dashboardService;

  @override
  State<RoleHomeBody> createState() => _RoleHomeBodyState();
}

class _RoleHomeBodyState extends State<RoleHomeBody> {
  late final HomeDashboardService _dashboardService;
  HomeDashboardData? _dashboard;
  bool _loadingDashboard = false;
  String? _dashboardError;

  AppPermissions get _permissions => widget.session.permissions;
  String get _email => widget.session.email;
  String? get _churchId => widget.session.profile.churchId?.trim().isNotEmpty == true
      ? widget.session.profile.churchId
      : null;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? HomeDashboardService();
    if (_showsDashboard) {
      _loadDashboard(forceRefresh: true);
    }
  }

  bool get _showsDashboard =>
      widget.layout == HomeRoleLayout.leader ||
      widget.layout == HomeRoleLayout.supervisor;

  Future<void> _loadDashboard({bool forceRefresh = false}) async {
    setState(() {
      if (_dashboard == null) {
        _loadingDashboard = true;
      }
      _dashboardError = null;
    });
    try {
      final data = await _dashboardService.loadForSession(
        widget.session,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _loadingDashboard = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _dashboardError = error.toString();
        _loadingDashboard = false;
      });
    }
  }

  void _openRegisterMember() {
    widget.onNavigate(
      RegisterMemberScreen(
        registeredBy: _email,
        churchId: _churchId,
        permissions: _permissions,
        actingLeaderId: widget.session.profile.leaderId,
      ),
      'newMember',
    );
  }

  void _openRegisterAttendance() {
    widget.onNavigate(
      MyAssignedCellsScreen(
        session: widget.session,
        registeredBy: _email,
        mode: MyAssignedCellsMode.attendance,
      ),
      'registerAttendance',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quickActions = _buildQuickActions(l10n);

    if (quickActions.isEmpty && !_showsDashboard) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        if (_showsDashboard) ...[
          _buildDashboardSection(context, l10n),
          const SizedBox(height: 8),
        ],
        if (quickActions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.homeQuickActionsTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111B21),
                  ),
            ),
          ),
          ...quickActions,
        ],
        ],
      ),
    );
  }

  Widget _buildDashboardSection(BuildContext context, AppLocalizations l10n) {
    if (_loadingDashboard) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dashboardError != null) {
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

    final data = _dashboard ?? const HomeDashboardData(memberCount: 0);
    final supervisorOnly =
        widget.layout == HomeRoleLayout.supervisor && !_permissions.isLeader;

    final summaryLines = <Widget>[
      Text(
        l10n.homeSummaryDisciplesCount(data.memberCount),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      if (!supervisorOnly) ...[
        const SizedBox(height: 8),
        Text(
          l10n.homeSummaryAssignedNewBelieversCount(data.newBelieverCount),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
      if (widget.layout == HomeRoleLayout.supervisor &&
          data.leaderCount != null) ...[
        const SizedBox(height: 8),
        Text(
          l10n.homeLeadersCount(data.leaderCount!),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ];

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
              children: summaryLines,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            l10n.homeTodayTitle,
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
                  l10n.homeCellBirthdaysTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                if (data.birthdaysToday.isEmpty)
                  Text(
                    l10n.homeBirthdaysEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  )
                else
                  ...data.birthdaysToday.map((person) {
                    final suffix = person.age != null
                        ? ' · ${l10n.memberAgeYears(person.age!)}'
                        : '';
                    final cell = person.cellCode?.trim().isNotEmpty == true
                        ? ' · ${person.cellCode}'
                        : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎂 '),
                          Expanded(
                            child: Text(
                              '${person.name}$suffix$cell',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildQuickActions(AppLocalizations l10n) {
    final entries = <({IconData icon, String title, String subtitle, VoidCallback onTap})>[];

    void add({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      entries.add((icon: icon, title: title, subtitle: subtitle, onTap: onTap));
    }

    switch (widget.layout) {
      case HomeRoleLayout.leader:
      case HomeRoleLayout.supervisor:
        if (_permissions.canRegisterMember) {
          add(
            icon: Icons.person_add_outlined,
            title: l10n.quickNewMemberTitle,
            subtitle: l10n.quickNewMemberSubtitle,
            onTap: _openRegisterMember,
          );
        }
        if (_permissions.canViewMyAssignedCell) {
          add(
            icon: Icons.event_available_outlined,
            title: l10n.homeRegisterAttendanceTitle,
            subtitle: l10n.homeRegisterAttendanceSubtitle,
            onTap: _openRegisterAttendance,
          );
        }
      case HomeRoleLayout.registrar:
        if (_permissions.canRegisterMember) {
          add(
            icon: Icons.person_add_outlined,
            title: l10n.quickNewMemberTitle,
            subtitle: l10n.quickNewMemberSubtitle,
            onTap: _openRegisterMember,
          );
        }
      case HomeRoleLayout.admin:
      case HomeRoleLayout.superAdmin:
        break;
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
}
