import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../auth/models/app_permissions.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../members/models/church_member.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../members/services/member_service.dart';
import '../models/baptism_assigned_member.dart';
import '../models/baptism_calendar_entry.dart';
import '../screens/register_baptism_believer_screen.dart';
import '../screens/select_baptism_members_screen.dart';
import '../services/baptism_calendar_service.dart';

class BaptismDayPanel extends StatefulWidget {
  const BaptismDayPanel({
    super.key,
    required this.selectedDate,
    required this.entries,
    required this.registeredBy,
    required this.churchId,
    required this.permissions,
    required this.baptismService,
    required this.memberService,
    this.actingLeaderId,
    this.busy = false,
    this.onBusyChanged,
    this.onMessage,
    this.onEntryCreated,
  });

  final DateTime selectedDate;
  final List<BaptismCalendarEntry> entries;
  final String registeredBy;
  final String? churchId;
  final AppPermissions permissions;
  final BaptismCalendarService baptismService;
  final MemberService memberService;
  final String? actingLeaderId;
  final bool busy;
  final ValueChanged<bool>? onBusyChanged;
  final ValueChanged<String>? onMessage;
  final VoidCallback? onEntryCreated;

  @override
  State<BaptismDayPanel> createState() => _BaptismDayPanelState();
}

class _BaptismDayPanelState extends State<BaptismDayPanel> {
  BaptismCalendarEntry? _activeEntry;
  late final TextEditingController _timeController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  Map<String, bool> _confirmedBaptized = {};
  bool _loadingConfirmationState = false;

  bool get _isPastBaptism => _isDateBeforeToday(widget.selectedDate);

  static bool _isDateBeforeToday(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(todayOnly);
  }

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();
    _syncActiveEntry(notify: false);
  }

  @override
  void didUpdateWidget(covariant BaptismDayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _syncActiveEntry();
      return;
    }

    final id = _activeEntry?.id;
    if (id == null) {
      if (widget.entries.isNotEmpty) _syncActiveEntry();
      return;
    }

    final updated =
        widget.entries.where((entry) => entry.id == id).firstOrNull;
    if (updated == null) {
      _syncActiveEntry();
      return;
    }

    if (updated.assignedMembers.length !=
            (_activeEntry?.assignedMembers.length ?? 0) ||
        updated.assignedMembers.any(
          (member) => !_activeEntry!.assignedMembers.any(
            (current) => current.memberId == member.memberId,
          ),
        )) {
      setState(() => _activeEntry = updated);
      if (_isPastBaptism) _loadConfirmationState();
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncActiveEntry({bool notify = true}) {
    final currentId = _activeEntry?.id;
    BaptismCalendarEntry? next;
    if (currentId != null) {
      next = widget.entries
          .where((entry) => entry.id == currentId)
          .firstOrNull;
    }
    next ??= widget.entries.isNotEmpty ? widget.entries.first : null;

    void apply() {
      _activeEntry = next;
      _loadEntryIntoForm(next);
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }

    if (_isPastBaptism && next != null) {
      _loadConfirmationState();
    }
  }

  Future<void> _loadConfirmationState() async {
    final entry = _activeEntry;
    if (entry == null || !_isPastBaptism) return;

    setState(() => _loadingConfirmationState = true);
    try {
      final map = <String, bool>{};
      for (final assigned in entry.assignedMembers) {
        final member =
            await widget.memberService.fetchMemberById(assigned.memberId);
        map[assigned.memberId] = member?.isBaptized ?? false;
      }
      if (!mounted) return;
      setState(() => _confirmedBaptized = map);
    } finally {
      if (mounted) setState(() => _loadingConfirmationState = false);
    }
  }

  void _loadEntryIntoForm(BaptismCalendarEntry? entry) {
    _timeController.text = entry?.time ?? '';
    _locationController.text = entry?.location ?? '';
    _notesController.text = entry?.notes ?? '';
  }

  String? get _memberAssignmentLeaderId {
    final permissions = widget.permissions;
    if (permissions.isAdmin || permissions.isSupervisor) return null;
    if (permissions.isLeader) return widget.actingLeaderId?.trim();
    return null;
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }

  void _setBusy(bool value) => widget.onBusyChanged?.call(value);

  void _showMessage(String message) => widget.onMessage?.call(message);

  Future<void> _createEntry() async {
    if (!widget.permissions.canRegisterBaptismCalendar) return;

    final l10n = context.l10n;
    _setBusy(true);
    try {
      await widget.baptismService.addEntry(
        BaptismCalendarEntry(
          baptismDate: widget.selectedDate,
          registeredAt: DateTime.now(),
          registeredBy: widget.registeredBy,
          churchId: widget.churchId,
        ),
      );
      widget.onEntryCreated?.call();
      _showMessage(l10n.baptismCalendarSuccess);
    } on FirebaseException catch (e) {
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } catch (_) {
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _saveEntry() async {
    if (_isPastBaptism) return;
    final entry = _activeEntry;
    final entryId = entry?.id;
    if (entryId == null || !widget.permissions.canRegisterBaptismCalendar) {
      return;
    }

    final l10n = context.l10n;
    final time = _timeController.text.trim();
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();

    _setBusy(true);
    try {
      await widget.baptismService.updateEntry(
        BaptismCalendarEntry(
          id: entryId,
          baptismDate: entry!.baptismDate,
          time: time.isEmpty ? null : time,
          location: location.isEmpty ? null : location,
          notes: notes.isEmpty ? null : notes,
          registeredAt: entry.registeredAt,
          registeredBy: entry.registeredBy,
          churchId: entry.churchId,
          assignedMembers: entry.assignedMembers,
        ),
      );
      _showMessage(l10n.baptismCalendarUpdated);
    } on FirebaseException catch (e) {
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } catch (_) {
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _assignMembers() async {
    if (_isPastBaptism) return;
    final entry = _activeEntry;
    final entryId = entry?.id;
    if (entryId == null || !widget.permissions.canAssignBaptismCalendarMembers) {
      return;
    }

    final l10n = context.l10n;
    final initialIds = entry!.assignedMembers
        .map((member) => member.memberId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final selected = await Navigator.of(context).push<List<ChurchMember>>(
      MaterialPageRoute<List<ChurchMember>>(
        builder: (_) => SelectBaptismMembersScreen(
          churchId: widget.churchId,
          memberService: widget.memberService,
          assignedLeaderId: _memberAssignmentLeaderId,
          initialSelectedIds: initialIds,
        ),
      ),
    );

    if (selected == null || !mounted) return;

    final assigned = selected
        .where((member) => member.id != null && member.id!.isNotEmpty)
        .map(
          (member) => BaptismAssignedMember(
            memberId: member.id!,
            fullName: member.fullName,
          ),
        )
        .toList();

    _setBusy(true);
    try {
      await widget.baptismService.updateAssignedMembers(
        entryId: entryId,
        members: assigned,
      );
      _showMessage(l10n.baptismCalendarMembersAssigned(assigned.length));
    } on FirebaseException catch (e) {
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _registerNewBelieverToBaptize() async {
    if (_isPastBaptism) return;
    if (!widget.permissions.canRegisterMember) return;

    final l10n = context.l10n;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => RegisterBaptismBelieverScreen(
          registeredBy: widget.registeredBy,
          churchId: widget.churchId,
          memberService: widget.memberService,
          permissions: widget.permissions,
          actingLeaderId: widget.actingLeaderId,
        ),
      ),
    );

    if (!mounted || result == null || result.trim().isEmpty) return;

    final memberId = result.trim();

    final entry = _activeEntry;
    final entryId = entry?.id;
    if (entryId == null) {
      _showMessage(l10n.baptismCalendarBelieverCreatedScheduleFirst);
      return;
    }

    final member = await widget.memberService.fetchMemberById(memberId);
    if (!mounted) return;
    if (member == null) {
      _showMessage(l10n.dashboardMemberNotFound);
      return;
    }

    if (!member.canBeAssignedToBaptism) {
      _showMessage(l10n.baptismCalendarBelieverAlreadyBaptized);
      return;
    }

    final current = entry!.assignedMembers;
    if (current.any((assigned) => assigned.memberId == memberId)) {
      _showMessage(l10n.baptismCalendarBelieverAlreadyAssigned(member.fullName));
      return;
    }

    final updated = [
      ...current,
      BaptismAssignedMember(
        memberId: memberId,
        fullName: member.fullName,
      ),
    ];

    _setBusy(true);
    try {
      await widget.baptismService.updateAssignedMembers(
        entryId: entryId,
        members: updated,
      );
      _showMessage(
        l10n.baptismCalendarBelieverCreatedAndAssigned(member.fullName),
      );
    } on FirebaseException catch (e) {
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _confirmBaptizedMembers() async {
    if (!_isPastBaptism || !widget.permissions.canConfirmBaptismMembers) {
      return;
    }

    final entry = _activeEntry;
    if (entry == null || entry.assignedMembers.isEmpty) return;

    final l10n = context.l10n;
    final assignedIds =
        entry.assignedMembers.map((member) => member.memberId).toSet();
    final baptized = _confirmedBaptized.entries
        .where((item) => item.value)
        .map((item) => item.key)
        .toList();
    final notBaptized = assignedIds
        .where((id) => !(_confirmedBaptized[id] ?? false))
        .toList();

    _setBusy(true);
    try {
      await widget.memberService.updateMembersBaptismConfirmation(
        baptizedMemberIds: baptized,
        notBaptizedMemberIds: notBaptized,
        baptizedAt: widget.selectedDate,
        performedBy: widget.registeredBy,
      );
      _showMessage(l10n.baptismCalendarConfirmBaptizedSuccess(baptized.length));
    } on FirebaseException catch (e) {
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } catch (_) {
      _showMessage(l10n.memberSaveUnexpectedError);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _openMemberDetail(String memberId) async {
    final member = await widget.memberService.fetchMemberById(memberId);
    if (!mounted) return;
    if (member == null) {
      _showMessage(context.l10n.dashboardMemberNotFound);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          member: member,
          registeredBy: widget.registeredBy,
          permissions: widget.permissions,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (_isPastBaptism) return;
    final entry = _activeEntry;
    final id = entry?.id;
    if (id == null || !widget.permissions.canRegisterBaptismCalendar) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.baptismCalendarDeleteTitle),
        content: Text(
          l10n.baptismCalendarDeleteConfirm(_formatDate(widget.selectedDate)),
        ),
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

    _setBusy(true);
    try {
      await widget.baptismService.deleteEntry(id);
      _showMessage(l10n.baptismCalendarDeleted);
    } on FirebaseException catch (e) {
      _showMessage(
        BaptismCalendarService.messageFromFirestoreException(e, l10n),
      );
    } finally {
      _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canRegister = widget.permissions.canRegisterBaptismCalendar;
    final canAssign = widget.permissions.canAssignBaptismCalendarMembers;
    final canConfirm = widget.permissions.canConfirmBaptismMembers;
    final canRegisterMember = widget.permissions.canRegisterMember;
    final entry = _activeEntry;
    final isPast = _isPastBaptism;
    final canEditEntry = canRegister && !isPast;

    if (widget.entries.isEmpty) {
      if (!canRegister) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.baptismCalendarDayEmpty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: widget.busy ? null : _createEntry,
            icon: const Icon(Icons.add),
            label: Text(l10n.baptismCalendarAddForDay),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPast) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.baptismCalendarPastReadOnlyHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.entries.length > 1) ...[
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.baptismCalendarSelectEvent,
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: entry?.id,
                    items: widget.entries
                        .where((item) => item.id != null)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              () {
                                final parts = <String>[
                                  if (item.time != null && item.time!.isNotEmpty)
                                    item.time!,
                                  if (item.location != null &&
                                      item.location!.isNotEmpty)
                                    item.location!,
                                ];
                                return parts.isEmpty
                                    ? _formatDate(item.baptismDate)
                                    : parts.join(' · ');
                              }(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: widget.busy
                        ? null
                        : (id) {
                            if (id == null) return;
                            setState(() {
                              _activeEntry = widget.entries
                                  .where((item) => item.id == id)
                                  .firstOrNull;
                              _loadEntryIntoForm(_activeEntry);
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (canEditEntry) ...[
              TextField(
                controller: _timeController,
                enabled: !widget.busy,
                decoration: InputDecoration(
                  labelText: l10n.baptismCalendarTime,
                  hintText: l10n.baptismCalendarTimeHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                enabled: !widget.busy,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.baptismCalendarLocation,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                enabled: !widget.busy,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.baptismCalendarNotes,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.busy ? null : _saveEntry,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.commonSave),
              ),
              const SizedBox(height: 20),
            ] else if (entry != null) ...[
              _ReadOnlyRow(
                label: l10n.baptismCalendarTime,
                value: entry.time,
              ),
              _ReadOnlyRow(
                label: l10n.baptismCalendarLocation,
                value: entry.location,
              ),
              _ReadOnlyRow(
                label: l10n.baptismCalendarNotes,
                value: entry.notes,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              isPast
                  ? l10n.baptismCalendarConfirmBaptizedSection
                  : l10n.baptismCalendarMembersSection,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isPast
                  ? l10n.baptismCalendarConfirmBaptizedHint
                  : l10n.baptismCalendarAssignedCount(
                      entry?.assignedMembers.length ?? 0,
                    ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            if (entry != null && entry.assignedMembers.isEmpty)
              Text(
                l10n.baptismCalendarMembersEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else if (entry != null && isPast) ...[
              if (_loadingConfirmationState)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...entry.assignedMembers.map((member) {
                  final isConfirmed =
                      _confirmedBaptized[member.memberId] ?? false;
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isConfirmed,
                    onChanged: widget.busy || !canConfirm
                        ? null
                        : (checked) {
                            setState(() {
                              _confirmedBaptized[member.memberId] =
                                  checked == true;
                            });
                          },
                    title: Text(member.fullName),
                    secondary: CircleAvatar(
                      child: Text(
                        member.fullName.isNotEmpty
                            ? member.fullName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              if (canConfirm && entry.assignedMembers.isNotEmpty) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: widget.busy || _loadingConfirmationState
                      ? null
                      : _confirmBaptizedMembers,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.baptismCalendarConfirmBaptizedAction),
                ),
              ],
            ] else if (entry != null)
              ...entry.assignedMembers.map(
                (member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      member.fullName.isNotEmpty
                          ? member.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(member.fullName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.busy
                      ? null
                      : () => _openMemberDetail(member.memberId),
                ),
              ),
            if (canAssign && !isPast) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: widget.busy ? null : _assignMembers,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(l10n.baptismCalendarAssignMembersAction),
              ),
              if (canRegisterMember) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: widget.busy ? null : _registerNewBelieverToBaptize,
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(l10n.baptismCalendarCreateBelieverToBaptize),
                ),
              ],
            ],
            if (canEditEntry) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: widget.busy ? null : _confirmDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  l10n.baptismCalendarDeleteAction,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
