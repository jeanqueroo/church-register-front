import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../church/models/church_record.dart';
import '../../church/services/church_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../../members/models/church_member.dart';
import '../../members/screens/member_detail_screen.dart';
import '../models/baptism_dashboard_data.dart';
import '../models/visit_chart_point.dart';
import '../services/baptism_dashboard_service.dart';
import '../widgets/dashboard_church_filter.dart';
import '../widgets/visit_count_bar_chart.dart';

class BaptismDashboardScreen extends StatefulWidget {
  const BaptismDashboardScreen({
    super.key,
    required this.session,
    this.dashboardService,
    this.churchService,
  });

  final UserSession session;
  final BaptismDashboardService? dashboardService;
  final ChurchService? churchService;

  @override
  State<BaptismDashboardScreen> createState() => _BaptismDashboardScreenState();
}

class _BaptismDashboardScreenState extends State<BaptismDashboardScreen> {
  late final BaptismDashboardService _dashboardService;
  late final ChurchService _churchService;

  String? _selectedChurchId;
  late int _selectedYear;
  int? _selectedMonth;
  List<ChurchRecord> _churches = [];
  BaptismDashboardData? _data;
  String? _scopeLabel;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? BaptismDashboardService();
    _churchService = widget.churchService ?? ChurchService();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.session.permissions.isSuperAdmin) {
        _churches = await _churchService.fetchChurches();
      }
      if (!mounted) return;
      _scopeLabel = _resolveScopeLabel(context.l10n);
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BaptismDashboardService.messageFromException(
          error,
          context.l10n,
        );
      });
    }
  }

  String? _resolveScopeLabel(AppLocalizations l10n) {
    final permissions = widget.session.permissions;
    if (permissions.isSuperAdmin) {
      if (_selectedChurchId == null) {
        return l10n.dashboardScopeAllChurches;
      }
      final church =
          _churches.where((item) => item.id == _selectedChurchId).firstOrNull;
      return church?.profile.name ?? l10n.dashboardScopeAllChurches;
    }
    if (permissions.isAdmin) {
      return l10n.dashboardScopeYourChurch;
    }
    return null;
  }

  String? get _churchIdForQuery {
    final permissions = widget.session.permissions;
    if (permissions.isSuperAdmin) return _selectedChurchId;
    return permissions.churchId?.trim();
  }

  List<int> get _selectableYears {
    final currentYear = DateTime.now().year;
    return List.generate(
      currentYear - BaptismDashboardService.firstSelectableYear + 1,
      (index) => currentYear - index,
    );
  }

  int get _maxSelectableMonth => BaptismDashboardService.lastSelectableMonth(
        _selectedYear,
        DateTime.now(),
      );

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final churchId = _churchIdForQuery;
      if (widget.session.permissions.isAdmin &&
          (churchId == null || churchId.isEmpty)) {
        throw StateError(context.l10n.dashboardAdminMissingChurch);
      }

      final data = await _dashboardService.load(
        churchId: churchId,
        selectedYear: _selectedYear,
        selectedMonth: _selectedMonth,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BaptismDashboardService.messageFromException(
          error,
          context.l10n,
        );
      });
    }
  }

  Future<void> _onYearChanged(int? year) async {
    if (year == null || year == _selectedYear) return;
    final maxMonth = BaptismDashboardService.lastSelectableMonth(
      year,
      DateTime.now(),
    );
    setState(() {
      _selectedYear = year;
      if (_selectedMonth != null && _selectedMonth! > maxMonth) {
        _selectedMonth = maxMonth;
      }
    });
    await _loadData();
  }

  Future<void> _onMonthSelected(int? month) async {
    if (month == _selectedMonth) return;
    setState(() => _selectedMonth = month);
    await _loadData();
  }

  Future<void> _onChurchChanged(String? churchId) async {
    setState(() => _selectedChurchId = churchId);
    _scopeLabel = _resolveScopeLabel(context.l10n);
    await _loadData();
  }

  String _periodLabel() {
    if (_selectedMonth == null) return '$_selectedYear';
    return '${_monthName(_selectedMonth!)} $_selectedYear';
  }

  String _monthName(int month) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMM(locale).format(DateTime(_selectedYear, month, 1));
  }

  String _monthShortName(int month) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMM(locale).format(DateTime(_selectedYear, month, 1));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _memberListSubtitle(AppLocalizations l10n, ChurchMember member) {
    final baptizedOn = _formatDate(member.baptizedAt);
    final source = member.registrationSource;
    if (source == null) return baptizedOn;
    return '$baptizedOn · ${source.localizedLabel(l10n)}';
  }

  void _openMemberDetail(ChurchMember member) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          member: member,
          registeredBy: widget.session.email,
          permissions: widget.session.permissions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.session.permissions;
    final l10n = context.l10n;

    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewBaptismDashboard,
      deniedMessage: l10n.baptismDashboardDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.baptismDashboardTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
              onPressed: _loading ? null : _loadData,
            ),
          ],
        ),
        body: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _data == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initialize,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_scopeLabel != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.water_outlined),
                title: Text(
                  _scopeLabel!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                subtitle: Text(_periodLabel()),
              ),
            ),
          if (widget.session.permissions.isSuperAdmin) ...[
            const SizedBox(height: 12),
            DashboardChurchFilter(
              churches: _churches,
              selectedChurchId: _selectedChurchId,
              enabled: !_loading,
              allChurchesLabel: l10n.dashboardScopeAllChurches,
              churchLabel: l10n.dashboardChurchLabel,
              onChanged: _onChurchChanged,
            ),
          ],
          const SizedBox(height: 16),
          _buildYearSelector(l10n),
          const SizedBox(height: 16),
          _buildChartCard(
            l10n,
            data,
            title: l10n.baptismDashboardChartTitleYear(_selectedYear),
          ),
          const SizedBox(height: 16),
          _buildMonthSelector(l10n),
          const SizedBox(height: 16),
          if (data != null) ...[
            ..._buildSummaryCards(l10n, data),
            const SizedBox(height: 16),
          ],
          if (!_loading) _buildBaptizedListSection(l10n, data),
        ],
      ),
    );
  }

  List<Widget> _buildSummaryCards(
    AppLocalizations l10n,
    BaptismDashboardData data,
  ) {
    final baptizedSubtitle = _selectedMonth == null
        ? l10n.baptismDashboardBaptizedInYear
        : l10n.baptismDashboardBaptizedInMonth;

    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.water_drop_outlined),
          title: Text(
            '${data.baptizedInRange}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(baptizedSubtitle),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.person_add_outlined),
          title: Text(
            '${data.newBelieversBaptizedInRange}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Text(l10n.baptismDashboardNewBelieversAmongBaptized),
        ),
      ),
    ];
  }

  Widget _buildChartCard(
    AppLocalizations l10n,
    BaptismDashboardData? data, {
    required String title,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              VisitCountBarChart(
                points: data?.baptismChartPoints ?? const [],
                period: VisitChartPeriod.month,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: DropdownButtonFormField<int>(
          initialValue: _selectedYear,
          decoration: InputDecoration(
            labelText: l10n.baptismDashboardSelectYear,
            border: InputBorder.none,
          ),
          items: _selectableYears
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text('$year'),
                ),
              )
              .toList(),
          onChanged: _loading ? null : _onYearChanged,
        ),
      ),
    );
  }

  Widget _buildMonthSelector(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.baptismDashboardSelectMonth,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(l10n.baptismDashboardAllMonths),
                  selected: _selectedMonth == null,
                  onSelected: _loading
                      ? null
                      : (_) => _onMonthSelected(null),
                ),
                for (var month = 1; month <= _maxSelectableMonth; month++)
                  FilterChip(
                    label: Text(_monthShortName(month)),
                    selected: _selectedMonth == month,
                    onSelected: _loading
                        ? null
                        : (_) => _onMonthSelected(month),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaptizedListSection(
    AppLocalizations l10n,
    BaptismDashboardData? data,
  ) {
    if (_selectedMonth == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.baptismDashboardListSelectMonth,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final members = data?.baptizedMembersInRange ?? const <ChurchMember>[];
    final listTitle =
        l10n.baptismDashboardListTitleMonth(_monthName(_selectedMonth!));
    final subtitle = members.isEmpty
        ? l10n.baptismDashboardListEmpty
        : l10n.baptismDashboardListCount(members.length);

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.list_outlined),
          title: Text(
            listTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          children: [
            if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  l10n.baptismDashboardListEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...members.map(
                (member) => ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      member.fullName.isNotEmpty
                          ? member.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(_memberListSubtitle(l10n, member)),
                  trailing: member.id != null
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: member.id != null
                      ? () => _openMemberDetail(member)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
