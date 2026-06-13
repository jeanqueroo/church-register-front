import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../models/admin_notification.dart';
import '../services/admin_notification_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({
    super.key,
    required this.session,
    this.notificationService,
  });

  final UserSession session;
  final AdminNotificationService? notificationService;

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late final AdminNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService =
        widget.notificationService ?? AdminNotificationService();
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

  Future<void> _openNotification(AdminNotification notification) async {
    final id = notification.id;
    if (id != null && !notification.read) {
      await _notificationService.markAsRead(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final permissions = widget.session.permissions;
    final uid = widget.session.uid;

    return RoleGate(
      permissions: permissions,
      allowed: permissions.canViewChurchNotifications,
      deniedMessage: l10n.adminNotificationsDenied,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminNotificationsTitle),
          actions: [
            StreamBuilder<List<AdminNotification>>(
              stream: _notificationService.watchForUser(uid),
              builder: (context, snapshot) {
                final hasUnread =
                    (snapshot.data ?? []).any((notification) => !notification.read);
                if (!hasUnread) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () =>
                      _notificationService.markAllAsReadForUser(uid),
                  child: Text(l10n.notificationsMarkRead),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<List<AdminNotification>>(
          stream: _notificationService.watchForUser(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.notificationsLoadError,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.adminNotificationsEmptyTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.adminNotificationsEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                  icon: Icons.warning_amber_outlined,
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
      ),
    );
  }
}
