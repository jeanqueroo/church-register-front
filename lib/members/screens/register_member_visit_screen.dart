import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import '../models/church_member.dart';
import '../models/member_visit.dart';
import '../models/spiritual_state.dart';
import '../models/visit_place.dart';
import '../services/member_visit_service.dart';

class RegisterMemberVisitScreen extends StatefulWidget {
  const RegisterMemberVisitScreen({
    super.key,
    required this.member,
    required this.leaderId,
    required this.registeredBy,
    this.permissions,
    this.visitService,
  });

  final ChurchMember member;
  final String leaderId;
  final String registeredBy;
  final AppPermissions? permissions;
  final MemberVisitService? visitService;

  @override
  State<RegisterMemberVisitScreen> createState() =>
      _RegisterMemberVisitScreenState();
}

class _RegisterMemberVisitScreenState extends State<RegisterMemberVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _durationController = TextEditingController();
  final _prayerRequestsController = TextEditingController();
  late final MemberVisitService _visitService;

  DateTime _visitDate = DateTime.now();
  VisitPlace? _visitPlace;
  bool? _prayerPerformed;
  bool? _needsFollowUp;
  SpiritualState? _spiritualState;
  bool _isSaving = false;

  AppPermissions get _permissions =>
      widget.permissions ?? AppPermissions.fromRoles([]);

  @override
  void initState() {
    super.initState();
    _visitService = widget.visitService ?? MemberVisitService();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _durationController.dispose();
    _prayerRequestsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _visitDate = picked);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_prayerPerformed == null || _needsFollowUp == null) {
      setState(() {});
      _showMessage(l10n.visitRegPrayerFollowUpRequired);
      return;
    }

    final memberId = widget.member.id;
    if (memberId == null || memberId.isEmpty) {
      _showMessage(l10n.visitRegInvalidMember);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _visitService.addVisit(
        MemberVisit(
          memberId: memberId,
          leaderId: widget.leaderId,
          visitDate: _visitDate,
          comment: _commentController.text.trim(),
          visitPlace: _visitPlace!,
          approximateDuration: _durationController.text.trim(),
          prayerPerformed: _prayerPerformed!,
          prayerRequests: _prayerRequestsController.text.trim(),
          needsFollowUp: _needsFollowUp!,
          spiritualState: _spiritualState,
          registeredAt: DateTime.now(),
          registeredBy: widget.registeredBy,
          churchId: widget.member.churchId ?? _permissions.churchId,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visitRegSaved)),
      );
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(MemberVisitService.messageFromFirestoreException(e, context.l10n));
    } catch (e) {
      if (!mounted) return;
      _showMessage(l10n.visitRegSaveFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _yesNoSelector({
    required AppLocalizations l10n,
    required String title,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.commonYes)),
            ButtonSegment(value: false, label: Text(l10n.commonNo)),
          ],
          selected: value != null ? {value} : <bool>{},
          emptySelectionAllowed: true,
          onSelectionChanged: _isSaving
              ? null
              : (selection) {
                  if (selection.isEmpty) return;
                  onChanged(selection.first);
                },
        ),
        if (value == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.visitRegSelectOption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canRegisterMemberVisits,
      deniedMessage: l10n.visitRegDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.visitRegTitle),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(widget.member.fullName),
                      subtitle: Text(widget.member.phone),
                    ),
                  ),
                  const SizedBox(height: 24),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.visitRegDate,
                      prefixIcon: const Icon(Icons.event_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    child: InkWell(
                      onTap: _isSaving ? null : _pickVisitDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _formatDate(_visitDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<VisitPlace>(
                    initialValue: _visitPlace,
                    decoration: InputDecoration(
                      labelText: l10n.visitRegPlace,
                      prefixIcon: const Icon(Icons.place_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    items: VisitPlace.values
                        .map(
                          (place) => DropdownMenuItem(
                            value: place,
                            child: Text(place.localizedLabel(l10n)),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _visitPlace = value),
                    validator: (value) =>
                        value == null ? l10n.visitRegSelectPlace : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    enabled: !_isSaving,
                    decoration: InputDecoration(
                      labelText: l10n.visitRegDuration,
                      hintText: l10n.visitRegDurationHint,
                      prefixIcon: const Icon(Icons.schedule_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _yesNoSelector(
                    l10n: l10n,
                    title: l10n.visitRegPrayerTitle,
                    value: _prayerPerformed,
                    onChanged: (value) =>
                        setState(() => _prayerPerformed = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _prayerRequestsController,
                    enabled: !_isSaving,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.visitRegPrayerRequests,
                      hintText: l10n.visitRegPrayerRequestsHint,
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.favorite_border),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _yesNoSelector(
                    l10n: l10n,
                    title: l10n.visitRegFollowUpTitle,
                    value: _needsFollowUp,
                    onChanged: (value) => setState(() => _needsFollowUp = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SpiritualState?>(
                    initialValue: _spiritualState,
                    decoration: InputDecoration(
                      labelText: l10n.visitRegSpiritualState,
                      prefixIcon: const Icon(Icons.church_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<SpiritualState?>(
                        value: null,
                        child: Text(l10n.visitRegSpiritualUnspecified),
                      ),
                      ...SpiritualState.values.map(
                        (state) => DropdownMenuItem(
                          value: state,
                          child: Text(state.localizedLabel(l10n)),
                        ),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _spiritualState = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    enabled: !_isSaving,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: l10n.visitRegComment,
                      hintText: l10n.visitRegCommentHint,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.visitRegCommentRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving ? l10n.commonSaving : l10n.visitRegSaveButton,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
