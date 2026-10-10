import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../church/models/church_record.dart';
import '../../church/services/church_service.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../models/offering_chart_period.dart';
import '../models/offering_dashboard_data.dart';
import '../services/offering_dashboard_service.dart';
import '../widgets/dashboard_church_filter.dart';
import '../widgets/offering_amount_bar_chart.dart';

class OfferingDashboardScreen extends StatefulWidget {
  const OfferingDashboardScreen({
    super.key,
    required this.session,
    this.dashboardService,
    this.churchService,
  });

  final UserSession session;
  final OfferingDashboardService? dashboardService;
  final ChurchService? churchService;

  @override
  State<OfferingDashboardScreen> createState() =>
      _OfferingDashboardScreenState();
}

class _OfferingDashboardScreenState extends State<OfferingDashboardScreen> {
  late final OfferingDashboardService _dashboardService;
  late final ChurchService _churchService;

  OfferingChartPeriod _period = OfferingChartPeriod.month;
  String? _selectedChurchId;
  List<ChurchRecord> _churches = [];
  OfferingDashboardData? _data;
  String? _scopeLabel;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? OfferingDashboardService();
    _churchService = widget.churchService ?? ChurchService();
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
        _error = OfferingDashboardService.messageFromException(
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

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final churchId = _churchIdForQuery;
      if (widget.session.permissions.isAdmin &&
          !widget.session.permissions.isSuperAdmin &&
          (churchId == null || churchId.isEmpty)) {
        throw StateError(context.l10n.dashboardAdminMissingChurch);
      }

      final data = await _dashboardService.load(
        period: _period,
        churchId: churchId,
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
        _error = OfferingDashboardService.messageFromException(
          error,
          context.l10n,
        );
      });
    }
  }

  Future<void> _onPeriodChanged(OfferingChartPeriod period) async {
    if (period == _period) return;
    setState(() => _period = period);
    await _loadData();
  }

  Future<void> _onChurchChanged(String? churchId) async {
    setState(() => _selectedChurchId = churchId);
    _scopeLabel = _resolveScopeLabel(context.l10n);
    await _loadData();
  }

  String _periodLabel(AppLocalizations l10n) {
    return _dashboardService.periodLabel(_period, DateTime.now());
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color ?? AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
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
      allowed: permissions.canViewOfferingDashboard,
      deniedMessage: l10n.offeringDashboardDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.offeringDashboardTitle),
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

    final data = _data ??
        const OfferingDashboardData(
          cashTotal: 0,
          transferTotal: 0,
          sessionCount: 0,
          chartPoints: [],
          byCell: [],
        );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_scopeLabel != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: Text(
                  _scopeLabel!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                subtitle: Text(_periodLabel(l10n)),
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
          Row(
            children: [
              _summaryCard(
                title: l10n.offeringDashboardCashTotal,
                value: OfferingDashboardService.formatAmount(data.cashTotal),
                icon: Icons.payments_outlined,
                color: const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                title: l10n.offeringDashboardTransferTotal,
                value:
                    OfferingDashboardService.formatAmount(data.transferTotal),
                icon: Icons.account_balance_outlined,
                color: const Color(0xFF1565C0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryCard(
                title: l10n.offeringDashboardGrandTotal,
                value: OfferingDashboardService.formatAmount(data.grandTotal),
                icon: Icons.savings_outlined,
                color: const Color(0xFF6A1B9A),
              ),
              const SizedBox(width: 12),
              _summaryCard(
                title: l10n.offeringDashboardSessionCount,
                value: '${data.sessionCount}',
                icon: Icons.event_note_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<OfferingChartPeriod>(
            segments: OfferingChartPeriod.values
                .map(
                  (period) => ButtonSegment(
                    value: period,
                    label: Text(period.localizedLabel(l10n)),
                  ),
                )
                .toList(),
            selected: {_period},
            onSelectionChanged: _loading
                ? null
                : (selection) => _onPeriodChanged(selection.first),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.offeringDashboardChartTitle,
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
                    OfferingAmountBarChart(
                      points: data.chartPoints,
                      period: _period,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.offeringDashboardByCell,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (data.byCell.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text(l10n.dashboardNoData)),
                    )
                  else
                    ...data.byCell.map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.groups_2_outlined),
                        title: Text(entry.cellCode),
                        subtitle: Text(
                          [
                            if (entry.cash > 0)
                              l10n.offeringDashboardCashSummary(
                                OfferingDashboardService.formatAmount(
                                  entry.cash,
                                ),
                              ),
                            if (entry.transfer > 0)
                              l10n.offeringDashboardTransferSummary(
                                OfferingDashboardService.formatAmount(
                                  entry.transfer,
                                ),
                              ),
                          ].join(' · '),
                        ),
                        trailing: Chip(
                          label: Text(
                            OfferingDashboardService.formatAmount(entry.total),
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.primaryLight.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
