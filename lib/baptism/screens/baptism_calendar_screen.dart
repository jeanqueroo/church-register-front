import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/widgets/form_section_title.dart';
import '../models/baptism_calendar_entry.dart';
import '../services/baptism_calendar_service.dart';
import '../widgets/month_calendar_view.dart';

class BaptismCalendarScreen extends StatefulWidget {
  const BaptismCalendarScreen({
    super.key,
    required this.registeredBy,
    this.churchId,
    this.baptismCalendarService,
    this.permissions,
  });

  final String registeredBy;
  final String? churchId;
  final BaptismCalendarService? baptismCalendarService;
  final AppPermissions? permissions;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.adminDefault();

  @override
  State<BaptismCalendarScreen> createState() => _BaptismCalendarScreenState();
}

class _BaptismCalendarScreenState extends State<BaptismCalendarScreen> {
  late final BaptismCalendarService _service;
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _service = widget.baptismCalendarService ?? BaptismCalendarService();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
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

  Future<void> _openRegisterSheet({DateTime? initialDate}) async {
    if (!widget._permissions.canRegisterBaptismCalendar) return;

    final l10n = context.l10n;
    final date = initialDate ?? _selectedDate ?? DateTime.now();
    final timeController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    var pickedDate = _dateOnly(date);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.baptismCalendarRegisterTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setSheetState(() => pickedDate = _dateOnly(selected));
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_formatDate(pickedDate)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: l10n.baptismCalendarTime,
                        hintText: l10n.baptismCalendarTimeHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.baptismCalendarLocation,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.baptismCalendarNotes,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.commonSave),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (saved != true || !mounted) {
      timeController.dispose();
      locationController.dispose();
      notesController.dispose();
      return;
    }

    setState(() => _actionInProgress = true);
    try {
      await _service.addEntry(
        BaptismCalendarEntry(
          baptismDate: pickedDate,
          time: timeController.text.trim().isEmpty
              ? null
              : timeController.text.trim(),
          location: locationController.text.trim().isEmpty
              ? null
              : locationController.text.trim(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          registeredAt: DateTime.now(),
          registeredBy: widget.registeredBy,
          churchId: widget.churchId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _selectedDate = pickedDate;
        _focusedMonth = DateTime(pickedDate.year, pickedDate.month);
      });
      _showMessage(l10n.baptismCalendarSuccess);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      timeController.dispose();
      locationController.dispose();
      notesController.dispose();
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _confirmDelete(BaptismCalendarEntry entry) async {
    final l10n = context.l10n;
    final id = entry.id;
    if (id == null || !widget._permissions.canRegisterBaptismCalendar) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.baptismCalendarDeleteTitle),
        content: Text(l10n.baptismCalendarDeleteConfirm(_formatDate(entry.baptismDate))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionInProgress = true);
    try {
      await _service.deleteEntry(id);
      if (!mounted) return;
      _showMessage(l10n.baptismCalendarDeleted);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Widget _buildEntryTile(BaptismCalendarEntry entry, {bool showDate = false}) {
    final details = <String>[
      if (entry.time != null && entry.time!.isNotEmpty) entry.time!,
      if (entry.location != null && entry.location!.isNotEmpty) entry.location!,
    ];
    final title = showDate
        ? [
            _formatDate(entry.baptismDate),
            ...details,
          ].join(' · ')
        : details.isEmpty
            ? _formatDate(entry.baptismDate)
            : details.join(' · ');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            showDate ? Icons.water_outlined : Icons.schedule_outlined,
          ),
        ),
        title: Text(title),
        subtitle: entry.notes != null && entry.notes!.isNotEmpty
            ? Text(entry.notes!)
            : null,
        trailing: widget._permissions.canRegisterBaptismCalendar
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _actionInProgress
                    ? null
                    : () => _confirmDelete(entry),
                tooltip: context.l10n.commonDelete,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canRegister = widget._permissions.canRegisterBaptismCalendar;

    return RoleGate(
      permissions: widget._permissions,
      allowed: widget._permissions.canViewBaptismCalendar,
      deniedMessage: l10n.baptismCalendarDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.baptismCalendarTitle),
        ),
        floatingActionButton: canRegister
            ? FloatingActionButton.extended(
                onPressed: _actionInProgress
                    ? null
                    : () => _openRegisterSheet(initialDate: _selectedDate),
                icon: const Icon(Icons.add),
                label: Text(l10n.baptismCalendarAdd),
              )
            : null,
        body: StreamBuilder<List<BaptismCalendarEntry>>(
          stream: _service.watchEntries(churchId: widget.churchId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
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
              );
            }

            final entries = snapshot.data ?? [];
            final selected = _selectedDate;
            final dayEntries =
                selected == null ? <BaptismCalendarEntry>[] : _entriesForDay(entries, selected);
            final upcoming = _upcomingEntries(entries);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                MonthCalendarView(
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  markedDates: _markedDates(entries),
                  onMonthChanged: (month) {
                    setState(() => _focusedMonth = DateTime(month.year, month.month));
                  },
                  onDateSelected: (date) {
                    setState(() => _selectedDate = date);
                  },
                ),
                const SizedBox(height: 16),
                FormSectionTitle(
                  selected == null
                      ? l10n.baptismCalendarSelectDay
                      : l10n.baptismCalendarDayTitle(_formatDate(selected)),
                ),
                if (dayEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.baptismCalendarDayEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ...dayEntries.map((entry) => _buildEntryTile(entry)),
                const SizedBox(height: 16),
                FormSectionTitle(l10n.baptismCalendarUpcoming),
                if (upcoming.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.baptismCalendarEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ...upcoming.map(
                    (entry) => _buildEntryTile(entry, showDate: true),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
