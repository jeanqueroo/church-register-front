import 'package:flutter/material.dart';

import '../../auth/models/app_permissions.dart';
import '../models/member_visit.dart';
import '../services/member_visit_service.dart';

class MemberVisitsSection extends StatelessWidget {
  const MemberVisitsSection({
    super.key,
    required this.memberId,
    required this.permissions,
    this.visitService,
  });

  final String memberId;
  final AppPermissions permissions;
  final MemberVisitService? visitService;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!permissions.canViewMemberVisits) {
      return const SizedBox.shrink();
    }

    final service = visitService ?? MemberVisitService();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visitas registradas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<MemberVisit>>(
            stream: service.watchVisits(memberId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No se pudieron cargar las visitas.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                );
              }

              final visits = snapshot.data ?? [];
              if (visits.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aún no hay visitas registradas.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                );
              }

              return Card(
                child: Column(
                  children: visits.map((visit) {
                    return Column(
                      children: [
                        ExpansionTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: Text(_formatDate(visit.visitDate)),
                          subtitle: Text(
                            '${visit.visitPlace.label}'
                            '${visit.needsFollowUp ? ' · Requiere seguimiento' : ''}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: visit.summaryLines.map((line) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      line,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        if (visit != visits.last) const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
