import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../members/services/member_service.dart';
import '../models/leader_notification.dart';
import '../services/leader_notification_service.dart';

class LeaderNotificationsScreen extends StatefulWidget {
  const LeaderNotificationsScreen({
    super.key,
    required this.session,
    this.notificationService,
    this.memberService,
  });

  final UserSession session;
  final LeaderNotificationService? notificationService;
  final MemberService? memberService;

  @override
  State<LeaderNotificationsScreen> createState() =>
      _LeaderNotificationsScreenState();
}

class _LeaderNotificationsScreenState extends State<LeaderNotificationsScreen> {
  late final LeaderNotificationService _notificationService;
  late final MemberService _memberService;

  @override
  void initState() {
    super.initState();
    _notificationService =
        widget.notificationService ?? LeaderNotificationService();
    _memberService = widget.memberService ?? MemberService();
    _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    final leaderId = widget.session.profile.leaderId;
    if (leaderId == null) return;
    try {
      await _notificationService.syncAssignmentsForLeader(
        leaderId: leaderId,
        recipientUserId: widget.session.uid,
      );
    } catch (_) {
      // La lista en tiempo real mostrará el error si las reglas fallan.
    }
  }

  String _formatWhen(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (day == today) return 'Hoy $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Ayer $time';
    }
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $time';
  }

  Future<void> _openNotification(LeaderNotification notification) async {
    final id = notification.id;
    if (id != null && !notification.read) {
      await _notificationService.markAsRead(
        userId: widget.session.uid,
        notificationId: id,
      );
    }

    final member = await _memberService.fetchMemberById(notification.memberId);
    if (!mounted) return;

    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El integrante ya no está disponible.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          member: member,
          registeredBy: widget.session.email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.session.uid;
    final leaderId = widget.session.profile.leaderId;
    if (leaderId == null || leaderId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Tu cuenta no está vinculada a un líder. '
              'Contacta al administrador.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          StreamBuilder<List<LeaderNotification>>(
            stream: _notificationService.watchForUser(uid),
            builder: (context, snapshot) {
              final hasUnread =
                  snapshot.data?.any((n) => !n.read) ?? false;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    _notificationService.markAllAsReadForUser(uid),
                child: const Text('Marcar leídas'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LeaderNotification>>(
        stream: _notificationService.watchForUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudieron cargar las notificaciones. '
                  'Revisa las reglas de Firestore para '
                  'users/{uid}/notifications (ver FIREBASE_SETUP.md).',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 56,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes notificaciones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando te asignen un integrante nuevo, '
                      'aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return WhatsappListTile(
                icon: Icons.person_add_alt_1_outlined,
                title: notification.title,
                subtitle:
                    '${notification.body}\n${_formatWhen(notification.createdAt)}',
                onTap: () => _openNotification(notification),
                showDivider: index < notifications.length - 1,
                highlighted: !notification.read,
                subtitleMaxLines: 3,
                trailing: notification.read
                    ? null
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
