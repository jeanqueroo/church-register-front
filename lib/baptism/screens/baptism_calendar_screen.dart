import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/widgets/form_section_title.dart';
import '../../members/services/member_service.dart';
import '../models/baptism_calendar_entry.dart';
import '../services/baptism_calendar_service.dart';
import '../widgets/baptism_day_panel.dart';
import '../widgets/month_calendar_view.dart';

class BaptismCalendarScreen extends StatefulWidget {
  const BaptismCalendarScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.actingLeaderId,
    this.baptismCalendarService,
    this.memberService,
    this.permissions,
  });

  final String registeredBy;
  final String? churchId;
  final String? actingLeaderId;
  final BaptismCalendarService? baptismCalendarService;
  final MemberService? memberService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<BaptismCalendarScreen> createState() => _BaptismCalendarScreenState();
}

class _BaptismCalendarScreenState extends State<BaptismCalendarScreen> {
  late final BaptismCalendarService _service;
  late final MemberService _memberService;
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  bool _actionInProgress = false;
  final _dayPanelKey = GlobalKey<BaptismDayPanelState>();
  final _dayScrollController = ScrollController();

  bool get _isEditingDay => _selectedDate != null;

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _service = widget.baptismCalendarService ?? BaptismCalendarService();
    _memberService = widget.memberService ?? MemberService();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }

  List<BaptismCalendarEntry> _entriesForDay(
    List<BaptismCalendarEntry> entries,
    DateTime day,
  ) {
    final target = _dateOnly(day);
    return entries
        .where((entry) => _dateOnly(entry.baptismDate) == target)
        .toList();
  }

  List<BaptismCalendarEntry> _upcomingEntries(
    List<BaptismCalendarEntry> entries,
  ) {
    final today = _dateOnly(DateTime.now());
    return entries
        .where((entry) => !_dateOnly(entry.baptismDate).isBefore(today))
        .toList();
  }

  Set<DateTime> _markedDates(List<BaptismCalendarEntry> entries) =>
      entries.map((entry) => _dateOnly(entry.baptismDate)).toSet();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openDay(DateTime date, {DateTime? focusMonth}) {
    setState(() {
      _selectedDate = _dateOnly(date);
      if (focusMonth != null) {
        _focusedMonth = DateTime(focusMonth.year, focusMonth.month);
      }
    });
  }

  void _closeDayEditor() {
    setState(() => _selectedDate = null);
  }

  Widget _buildUpcomingTile(BaptismCalendarEntry entry) {
    final details = <String>[
      _formatDate(entry.baptismDate),
      if (entry.time != null && entry.time!.isNotEmpty) entry.time!,
      if (entry.location != null && entry.location!.isNotEmpty) entry.location!,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.water_outlined),
        ),
        title: Text(details.join(' · ')),
        subtitle: Text(
          context.l10n.baptismCalendarAssignedCount(
            entry.assignedMembers.length,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDay(
          entry.baptismDate,
          focusMonth: entry.baptismDate,
        ),
      ),
    );
  }

  static bool _isDateBeforeToday(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(todayOnly);
  }

  Widget? _buildDayFloatingActions({
    required DateTime selectedDate,
    required List<BaptismCalendarEntry> dayEntries,
    required AppPermissions permissions,
    required bool busy,
  }) {
    if (_isDateBeforeToday(selectedDate)) return null;

    final hasScheduledEntry =
        dayEntries.any((entry) => entry.id != null && entry.id!.isNotEmpty);
    final canAssign =
        permissions.canAssignBaptismCalendarMembers && hasScheduledEntry;
    final canRegister = canAssign && permissions.canRegisterMember;
    if (!canAssign && !canRegister) return null;

    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canAssign)
          Padding(
            padding: EdgeInsets.only(bottom: canRegister ? 12 : 0),
            child: FloatingActionButton.extended(
              heroTag: 'baptism_assign_members',
              onPressed: busy
                  ? null
                  : () => _dayPanelKey.currentState?.assignMembers(),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.baptismCalendarAssignMembersAction),
            ),
          ),
        if (canRegister)
          FloatingActionButton.extended(
            heroTag: 'baptism_register_believer',
            onPressed: busy
                ? null
                : () =>
                    _dayPanelKey.currentState?.registerNewBelieverToBaptize(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.baptismCalendarCreateBelieverToBaptize),
          ),
      ],
    );
  }

  bool _showsDayFloatingActions({
    required DateTime selectedDate,
    required List<BaptismCalendarEntry> dayEntries,
    required AppPermissions permissions,
  }) {
    if (_isDateBeforeToday(selectedDate)) return false;

    final hasScheduledEntry =
        dayEntries.any((entry) => entry.id != null && entry.id!.isNotEmpty);
    return permissions.canAssignBaptismCalendarMembers && hasScheduledEntry;
  }

  double _dayEditorBottomInset({
    required DateTime selectedDate,
    required List<BaptismCalendarEntry> dayEntries,
    required AppPermissions permissions,
  }) {
    if (!_showsDayFloatingActions(
      selectedDate: selectedDate,
      dayEntries: dayEntries,
      permissions: permissions,
    )) {
      return 24;
    }

    final safe = MediaQuery.paddingOf(context).bottom;
    final twoFabActions = permissions.canRegisterMember;
    return safe + (twoFabActions ? 240 : 140);
  }

  void _onAssignedMembersExpanded(bool expanded) {
    if (!expanded) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted || !_dayScrollController.hasClients) return;
        _dayScrollController.animateTo(
          _dayScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canViewBaptismCalendar,
      deniedMessage: l10n.baptismCalendarDenied,
      child: PopScope(
        canPop: !_isEditingDay,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _closeDayEditor();
        },
        child: StreamBuilder<List<BaptismCalendarEntry>>(
          stream: _service.watchEntries(churchId: widget.churchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(title: Text(l10n.baptismCalendarTitle)),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: Text(l10n.baptismCalendarTitle)),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.baptismCalendarLoadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              );
            }

            final entries = snapshot.data ?? [];
            final selected = _selectedDate;
            final dayEntries = selected == null
                ? <BaptismCalendarEntry>[]
                : _entriesForDay(entries, selected);
            final upcoming = _upcomingEntries(entries);

            return Scaffold(
              appBar: AppBar(
                leading: _isEditingDay
                    ? BackButton(onPressed: _closeDayEditor)
                    : null,
                title: Text(
                  _isEditingDay && selected != null
                      ? l10n.baptismCalendarDayTitle(_formatDate(selected))
                      : l10n.baptismCalendarTitle,
                ),
              ),
              floatingActionButton: _isEditingDay && selected != null
                  ? _buildDayFloatingActions(
                      selectedDate: selected,
                      dayEntries: dayEntries,
                      permissions: widget._permissions,
                      busy: _actionInProgress,
                    )
                  : null,
              body: _isEditingDay && selected != null
                  ? ListView(
                      controller: _dayScrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        _dayEditorBottomInset(
                          selectedDate: selected,
                          dayEntries: dayEntries,
                          permissions: widget._permissions,
                        ),
                      ),
                      children: [
                        BaptismDayPanel(
                          key: _dayPanelKey,
                          selectedDate: selected,
                          entries: dayEntries,
                          registeredBy: widget.registeredBy,
                          churchId: widget.churchId,
                          permissions: widget._permissions,
                          baptismService: _service,
                          memberService: _memberService,
                          actingLeaderId: widget.actingLeaderId,
                          busy: _actionInProgress,
                          onBusyChanged: (busy) =>
                              setState(() => _actionInProgress = busy),
                          onMessage: _showMessage,
                          onAssignedMembersExpansionChanged:
                              _onAssignedMembersExpanded,
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        MonthCalendarView(
                          focusedMonth: _focusedMonth,
                          selectedDate: null,
                          markedDates: _markedDates(entries),
                          onMonthChanged: (month) {
                            setState(
                              () => _focusedMonth =
                                  DateTime(month.year, month.month),
                            );
                          },
                          onDateSelected: _openDay,
                        ),
                        const SizedBox(height: 16),
                        FormSectionTitle(l10n.baptismCalendarUpcoming),
                        if (upcoming.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              l10n.baptismCalendarEmpty,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          )
                        else
                          ...upcoming.map(_buildUpcomingTile),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
