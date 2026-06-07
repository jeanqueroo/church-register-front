import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../core/locale/l10n_extensions.dart';
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
      await _notificationService.syncAssignmentsForLeader(leaderId);
    } catch (_) {
      // La lista en tiempo real mostrará el error si las reglas fallan.
    }
  }

  String _formatWhen(DateTime date) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (day == today) return l10n.notificationsToday(time);
    if (day == today.subtract(const Duration(days: 1))) {
      return l10n.notificationsYesterday(time);
    }
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $time';
  }

  Future<void> _openNotification(LeaderNotification notification) async {
    final id = notification.id;
    if (id != null && !notification.read) {
      await _notificationService.markAsRead(id);
    }

    final member = await _memberService.fetchMemberById(notification.memberId);
    if (!mounted) return;

    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsMemberUnavailable)),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          member: member,
          registeredBy: widget.session.email,
          memberService: _memberService,
          permissions: widget.session.permissions,
          leaderId: widget.session.profile.leaderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final leaderId = widget.session.profile.leaderId;
    if (leaderId == null || leaderId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notificationsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.notificationsLeaderNotLinked,
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
        title: Text(l10n.notificationsTitle),
        actions: [
          StreamBuilder<List<LeaderNotification>>(
            stream: _notificationService.watchForLeader(leaderId),
            builder: (context, snapshot) {
              final hasUnread =
                  snapshot.data?.any((n) => !n.read) ?? false;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    _notificationService.markAllAsReadForLeader(leaderId),
                child: Text(l10n.notificationsMarkRead),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LeaderNotification>>(
        stream: _notificationService.watchForLeader(leaderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.notificationsLoadError,
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
                      l10n.notificationsEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.notificationsEmptySubtitle,
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
                title: notification.localizedTitle(l10n),
                subtitle:
                    '${notification.localizedBody(l10n)}\n${_formatWhen(notification.createdAt)}',
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
