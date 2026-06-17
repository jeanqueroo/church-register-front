import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../cells/models/church_cell.dart';
import '../../cells/screens/cell_detail_screen.dart';
import '../../church/models/church_record.dart';
import '../../church/services/church_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../models/cell_dashboard_data.dart';
import '../models/visit_chart_point.dart';
import '../services/cell_dashboard_service.dart';
import '../widgets/dashboard_church_filter.dart';
import '../widgets/visit_count_bar_chart.dart';

class CellDashboardScreen extends StatefulWidget {
  const CellDashboardScreen({
    super.key,
    required this.session,
    this.dashboardService,
    this.churchService,
  });

  final UserSession session;
  final CellDashboardService? dashboardService;
  final ChurchService? churchService;

  @override
  State<CellDashboardScreen> createState() => _CellDashboardScreenState();
}

class _CellDashboardScreenState extends State<CellDashboardScreen> {
  late final CellDashboardService _dashboardService;
  late final ChurchService _churchService;

  String? _selectedChurchId;
  late int _selectedYear;
  int? _selectedMonth;
  List<ChurchRecord> _churches = [];
  CellDashboardData? _data;
  String? _scopeLabel;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? CellDashboardService();
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
        _error = CellDashboardService.messageFromException(
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
      currentYear - CellDashboardService.firstSelectableYear + 1,
      (index) => currentYear - index,
    );
  }

  int get _maxSelectableMonth => CellDashboardService.lastSelectableMonth(
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
        _error = CellDashboardService.messageFromException(
          error,
          context.l10n,
        );
      });
    }
  }

  Future<void> _onYearChanged(int? year) async {
    if (year == null || year == _selectedYear) return;
    final maxMonth = CellDashboardService.lastSelectableMonth(
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _cellListSubtitle(ChurchCell cell) {
    final parts = <String>[_formatDate(cell.registeredAt)];
    final leader = cell.leaderName?.trim();
    if (leader != null && leader.isNotEmpty) {
      parts.add(leader);
    }
    return parts.join(' · ');
  }

  void _openCellDetail(ChurchCell cell) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CellDetailScreen(
          cell: cell,
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
      allowed: permissions.canViewCellDashboard,
      deniedMessage: l10n.cellDashboardDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.cellDashboardTitle),
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
                leading: const Icon(Icons.groups_2_outlined),
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
            title: l10n.cellDashboardChartTitleYear(_selectedYear),
          ),
          const SizedBox(height: 16),
          _buildMonthSelector(l10n),
          const SizedBox(height: 16),
          if (data != null) ...[
            _buildSummaryCard(l10n, data),
            const SizedBox(height: 16),
          ],
          if (!_loading) _buildCellsListSection(l10n, data),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n, CellDashboardData data) {
    final subtitle = _selectedMonth == null
        ? l10n.cellDashboardCreatedInYear
        : l10n.cellDashboardCreatedInMonth;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.add_home_outlined),
        title: Text(
          '${data.cellsCreatedInRange}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildChartCard(
    AppLocalizations l10n,
    CellDashboardData? data, {
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
                points: data?.cellChartPoints ?? const [],
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
          value: _selectedYear,
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

  Widget _buildCellsListSection(
    AppLocalizations l10n,
    CellDashboardData? data,
  ) {
    if (_selectedMonth == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.cellDashboardListSelectMonth,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final cells = data?.cellsInRange ?? const <ChurchCell>[];
    final listTitle =
        l10n.cellDashboardListTitleMonth(_monthName(_selectedMonth!));
    final subtitle = cells.isEmpty
        ? l10n.cellDashboardListEmpty
        : l10n.cellDashboardListCount(cells.length);

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
            if (cells.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  l10n.cellDashboardListEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...cells.map(
                (cell) => ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      cell.code.isNotEmpty ? cell.code[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(cell.displayLabel),
                  subtitle: Text(_cellListSubtitle(cell)),
                  trailing: cell.id != null
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: cell.id != null ? () => _openCellDetail(cell) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
