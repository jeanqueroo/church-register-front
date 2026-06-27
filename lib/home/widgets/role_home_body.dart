import 'package:flutter/material.dart';

import '../../cells/screens/my_assigned_cells_screen.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../auth/models/app_permissions.dart';
import '../../auth/models/user_profile.dart';
import '../../members/screens/register_member_screen.dart';
import '../home_role_layout.dart';
import '../models/home_dashboard_data.dart';
import '../services/home_dashboard_service.dart';
import 'home_design_widgets.dart';

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
            HomeSectionHeader(title: l10n.homeQuickActionsTitle),
            ...quickActions,
          ],
        ],
      ),
    );
  }

  List<HomeStatCardData> _buildLeaderStatCards(
    AppLocalizations l10n,
    HomeDashboardData data,
  ) {
    if (widget.layout == HomeRoleLayout.supervisor) {
      return _buildSupervisorStatCards(l10n, data);
    }

    return _buildOwnPastoralStatCards(l10n, data);
  }

  List<HomeStatCardData> _buildOwnPastoralStatCards(
    AppLocalizations l10n,
    HomeDashboardData data,
  ) {
    final cards = <HomeStatCardData>[];

    if (data.hasOwnCell) {
      cards.add(
        HomeStatCardData(
          value: '${data.memberCount}',
          title: l10n.homeStatMyDisciplesTitle,
          subtitle: l10n.homeStatMyDisciplesSubtitle,
          icon: HomeStatStyles.disciples.icon,
          backgroundColor: HomeStatStyles.disciples.bg,
          foregroundColor: HomeStatStyles.disciples.fg,
        ),
      );
    }

    cards.add(
      HomeStatCardData(
        value: '${data.newBelieverCount}',
        title: l10n.homeStatMyNewBelieversTitle,
        subtitle: l10n.homeStatMyNewBelieversSubtitle,
        icon: HomeStatStyles.newBelievers.icon,
        backgroundColor: HomeStatStyles.newBelievers.bg,
        foregroundColor: HomeStatStyles.newBelievers.fg,
      ),
    );

    return cards;
  }

  List<HomeStatCardData> _buildSupervisorStatCards(
    AppLocalizations l10n,
    HomeDashboardData data,
  ) {
    final cards = _buildOwnPastoralStatCards(l10n, data);

    if (data.leaderCount != null) {
      cards.add(
        HomeStatCardData(
          value: '${data.leaderCount}',
          title: l10n.homeStatMyAssignedLeadersTitle,
          subtitle: l10n.homeStatMyAssignedLeadersSubtitle,
          icon: HomeStatStyles.leaders.icon,
          backgroundColor: HomeStatStyles.leaders.bg,
          foregroundColor: HomeStatStyles.leaders.fg,
        ),
      );
    }

    return cards;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(title: l10n.homeSummaryTitle),
        HomeStatCardsRow(cards: _buildLeaderStatCards(l10n, data)),
        HomeSectionHeader(title: l10n.homeTodayTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: context.churchPalette.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeCellBirthdaysTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.churchPalette.primary,
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
        ),
        const SizedBox(height: 8),
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
        HomeQuickActionTile(
          icon: entries[i].icon,
          title: entries[i].title,
          subtitle: entries[i].subtitle,
          onTap: entries[i].onTap,
          accentColor: homeQuickActionAccent(i),
          showDivider: i < entries.length - 1,
        ),
    ];
  }
}
