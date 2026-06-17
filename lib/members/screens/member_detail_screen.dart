import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/locale/l10n_extensions.dart';
import '../../core/locale/weekday_labels.dart';
import '../../auth/models/app_permissions.dart';
import '../../l10n/app_localizations.dart';
import '../models/church_member.dart';
import '../models/member_history_event.dart';
import '../services/member_service.dart';
import '../widgets/member_visits_section.dart';
import 'register_member_screen.dart';
import 'register_member_visit_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({
    super.key,
    required this.member,
    required this.registeredBy,
    this.memberService,
    this.permissions,
    this.leaderId,
  });

  final ChurchMember member;
  final String registeredBy;
  final MemberService? memberService;
  final AppPermissions? permissions;
  final String? leaderId;

  AppPermissions get _permissions =>
      permissions ?? AppPermissions.fromRoles([]);

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String? get _visitLeaderId {
    final assigned = member.assignedLeaderId?.trim();
    if (assigned != null && assigned.isNotEmpty) return assigned;
    final fromScreen = leaderId?.trim();
    if (fromScreen != null && fromScreen.isNotEmpty) return fromScreen;
    return null;
  }

  bool get _canRegisterVisit =>
      _permissions.canRegisterMemberVisits &&
      member.id != null &&
      member.id!.isNotEmpty &&
      _visitLeaderId != null;

  Future<void> _registerVisit(BuildContext context) async {
    if (!_canRegisterVisit) return;
    final visitLeaderId = _visitLeaderId;
    if (visitLeaderId == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMemberVisitScreen(
          member: member,
          leaderId: visitLeaderId,
          registeredBy: registeredBy,
          permissions: _permissions,
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RegisterMemberScreen(
          registeredBy: registeredBy,
          churchId: _permissions.churchId,
          memberService: memberService,
          memberToEdit: member,
          permissions: _permissions,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final id = member.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.memberDetailDeleteTitle),
        content: Text(l10n.memberDetailDeleteConfirm(member.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await (memberService ?? MemberService()).deleteMember(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.memberDetailDeletedSuccess)),
      );
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            MemberService.messageFromFirestoreException(e, context.l10n),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(member.fullName),
        actions: [
          if (_permissions.canManageMembers) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.commonEdit,
              onPressed: () => _edit(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.commonDelete,
              onPressed: () => _delete(context),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Section(
            title: l10n.memberDetailSectionPersonal,
            rows: _personalRows(l10n),
          ),
          _Section(
            title: l10n.memberDetailSectionAddress,
            rows: _addressRows(l10n),
          ),
          if (member.assignedLeaderName != null ||
              member.isCellMemberAssignment)
            _Section(
              title: l10n.memberDetailSectionLeader,
              rows: _leaderRows(l10n),
            ),
          _Section(
            title: l10n.memberDetailSectionCellSchedule,
            rows: _cellScheduleRows(l10n),
          ),
          if (member.observations != null && member.observations!.isNotEmpty)
            _Section(
              title: l10n.memberDetailSectionObservations,
              rows: [_Row('', member.observations)],
            ),
          if (member.id != null)
            MemberVisitsSection(
              memberId: member.id!,
              permissions: _permissions,
            ),
          if (member.hasTrackedSpiritualJourney)
            _Section(
              title: l10n.memberDetailSectionJourney,
              rows: _journeyRows(l10n),
            ),
          if (member.id != null && _permissions.canManageMembers)
            _MemberHistorySection(
              memberId: member.id!,
              memberService: memberService ?? MemberService(),
              formatDate: _formatDate,
            ),
          _Section(
            title: l10n.memberDetailSectionRegistration,
            rows: _registrationRows(l10n),
          ),
          const SizedBox(height: 16),
          if (_canRegisterVisit) ...[
            FilledButton.icon(
              onPressed: () => _registerVisit(context),
              icon: const Icon(Icons.event_note_outlined),
              label: Text(l10n.memberDetailRegisterVisit),
            ),
            const SizedBox(height: 12),
          ],
          if (_permissions.canManageMembers) ...[
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.memberDetailEditMember),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.memberDetailDeleteMember),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_Row> _personalRows(AppLocalizations l10n) {
    return [
      _Row(l10n.memberDetailFirstName, member.firstName),
      _Row(l10n.memberDetailLastName, member.lastName),
      _Row(
        l10n.memberDetailGender,
        member.gender?.localizedLabel(l10n),
      ),
      _Row(
        l10n.memberDetailIdDocument,
        member.idDocumentType?.localizedLabel(l10n),
      ),
      _Row(l10n.memberDetailIdDocumentNumber, member.idDocumentNumber),
      _Row(l10n.memberDetailPhone, member.phone),
      _Row(l10n.memberDetailBirthDate, _formatDate(member.birthDate)),
      _Row(
        l10n.memberDetailAge,
        member.age != null ? l10n.memberAgeYears(member.age!) : null,
      ),
      _Row(l10n.memberDetailOccupation, member.occupation),
      _Row(
        l10n.memberDetailMaritalStatus,
        member.maritalStatus?.localizedLabel(l10n),
      ),
      _Row(
        l10n.memberDetailWantsVisit,
        member.wantsVisit ? l10n.commonYes : l10n.commonNo,
      ),
    ];
  }

  List<_Row> _addressRows(AppLocalizations l10n) {
    return [
      _Row(l10n.addressStreetOptional, member.street),
      _Row(l10n.addressNumber, member.streetNumber),
      _Row(l10n.addressNeighborhood, member.neighborhood),
      _Row(l10n.addressLocality, member.locality),
      _Row(l10n.addressStateProvince, member.stateProvince),
      _Row(l10n.addressPostalCode, member.postalCode),
    ];
  }

  List<_Row> _leaderRows(AppLocalizations l10n) {
    return [
      _Row(l10n.memberDetailAssignmentKind, member.assignmentKindLabel(l10n)),
      _Row(l10n.memberDetailLeaderName, member.assignedLeaderName),
      _Row(l10n.memberDetailCell, member.assignedLeaderCellCode),
      _Row(l10n.memberDetailAssignedCell, member.assignedCellCode),
      _Row(
        l10n.memberDetailDistance,
        member.assignedDistanceKm != null
            ? l10n.memberDetailDistanceKm(
                member.assignedDistanceKm!.toStringAsFixed(1),
              )
            : null,
      ),
    ];
  }

  List<_Row> _cellScheduleRows(AppLocalizations l10n) {
    return [
      _Row(l10n.memberDetailCellDay, localizedWeekday(l10n, member.cellDay)),
      _Row(l10n.memberDetailCellTime, member.cellTime),
      _Row(l10n.memberDetailCellZone, member.cellZone),
    ];
  }

  List<_Row> _journeyRows(AppLocalizations l10n) {
    return [
      _Row(
        l10n.memberDetailRegistrationSource,
        member.registrationSourceLabel(l10n),
      ),
      _Row(
        l10n.memberDetailPastoralAssignedAt,
        member.pastoralAssignedAt != null
            ? _formatDate(member.pastoralAssignedAt)
            : null,
      ),
      _Row(
        l10n.memberDetailCellAssignedAt,
        member.cellAssignedAt != null ? _formatDate(member.cellAssignedAt) : null,
      ),
      _Row(
        l10n.memberDetailBaptizedAt,
        member.isBaptized ? _formatDate(member.baptizedAt) : null,
      ),
      if (member.followedPastoralCellBaptismJourney)
        _Row('', l10n.memberDetailJourneyComplete),
    ];
  }

  List<_Row> _registrationRows(AppLocalizations l10n) {
    return [
      _Row(
        l10n.memberDetailEntrySource,
        member.entrySourceLabel(l10n),
      ),
      _Row(
        l10n.memberDetailLeadershipStatus,
        member.leadershipStatusLabel(l10n),
      ),
      _Row(l10n.memberDetailFormDate, _formatDate(member.formDate)),
      _Row(l10n.memberDetailVolunteer, member.volunteer),
      _Row(l10n.memberDetailRegisteredBy, member.registeredBy),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.hasValue).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: visible
                    .map(
                      (row) => ListTile(
                        title: row.label.isNotEmpty ? Text(row.label) : null,
                        subtitle: Text(row.value!),
                        dense: row.label.isEmpty,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  bool get hasValue => value != null && value!.trim().isNotEmpty;
}

class _MemberHistorySection extends StatelessWidget {
  const _MemberHistorySection({
    required this.memberId,
    required this.memberService,
    required this.formatDate,
  });

  final String memberId;
  final MemberService memberService;
  final String Function(DateTime?) formatDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StreamBuilder<List<MemberHistoryEvent>>(
      stream: memberService.watchMemberHistory(memberId),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <MemberHistoryEvent>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (events.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.memberDetailHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < events.length; i++)
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(events[i].type.localizedLabel(l10n)),
                        subtitle: Text(
                          [
                            formatDate(events[i].occurredAt),
                            if (events[i].performedBy?.trim().isNotEmpty ==
                                true)
                              events[i].performedBy!.trim(),
                          ].join(' · '),
                        ),
                        dense: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
