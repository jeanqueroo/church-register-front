import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../../auth/widgets/role_gate.dart';
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
    if (!_formKey.currentState!.validate()) return;
    if (_prayerPerformed == null || _needsFollowUp == null) {
      setState(() {});
      _showMessage('Indica si se realizó oración y si necesita seguimiento.');
      return;
    }

    final memberId = widget.member.id;
    if (memberId == null || memberId.isEmpty) {
      _showMessage('El integrante no tiene identificador válido.');
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
        const SnackBar(content: Text('Visita registrada')),
      );
      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(MemberVisitService.messageFromFirestoreException(e));
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo registrar la visita.');
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
          segments: const [
            ButtonSegment(value: true, label: Text('Sí')),
            ButtonSegment(value: false, label: Text('No')),
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
              'Selecciona una opción',
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
    return RoleGate(
      permissions: _permissions,
      allowed: _permissions.canRegisterMemberVisits,
      deniedMessage: 'Solo el líder puede registrar visitas a sus integrantes.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar visita'),
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
                    decoration: const InputDecoration(
                      labelText: 'Fecha de la visita *',
                      prefixIcon: Icon(Icons.event_outlined),
                      border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Lugar de la visita *',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: VisitPlace.values
                        .map(
                          (place) => DropdownMenuItem(
                            value: place,
                            child: Text(place.label),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _visitPlace = value),
                    validator: (value) =>
                        value == null ? 'Selecciona el lugar' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Duración aproximada de la visita',
                      hintText: 'Ej: 30 min, 1 hora',
                      prefixIcon: Icon(Icons.schedule_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _yesNoSelector(
                    title: 'Se realizó oración *',
                    value: _prayerPerformed,
                    onChanged: (value) =>
                        setState(() => _prayerPerformed = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _prayerRequestsController,
                    enabled: !_isSaving,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Peticiones de oración',
                      hintText: 'Opcional: motivos o peticiones compartidas',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.favorite_border),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _yesNoSelector(
                    title: 'Necesita seguimiento *',
                    value: _needsFollowUp,
                    onChanged: (value) => setState(() => _needsFollowUp = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SpiritualState?>(
                    initialValue: _spiritualState,
                    decoration: const InputDecoration(
                      labelText: 'Estado espiritual (opcional)',
                      prefixIcon: Icon(Icons.church_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<SpiritualState?>(
                        value: null,
                        child: Text('Sin especificar'),
                      ),
                      ...SpiritualState.values.map(
                        (state) => DropdownMenuItem(
                          value: state,
                          child: Text(state.label),
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
                    decoration: const InputDecoration(
                      labelText: 'Comentario *',
                      hintText: 'Resumen de la visita, temas tratados...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Escribe un comentario';
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
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar visita'),
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
