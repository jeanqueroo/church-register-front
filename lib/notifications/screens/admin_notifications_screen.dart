import 'package:flutter/material.dart';

import '../../auth/models/user_profile.dart';
import '../../auth/widgets/role_gate.dart';
import '../../core/locale/l10n_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/whatsapp_list_tile.dart';
import '../../cells/cell_member_capacity.dart';
import '../../cells/screens/split_cell_from_capacity_screen.dart';
import '../../members/services/member_service.dart';
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
  final _memberService = MemberService();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _canSplitCellFromNotification(String cellId) async {
    final memberCount = await _memberService.countMembersInCell(cellId);
    return memberCount > CellMemberCapacity.maxMembers;
  }

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
    final l10n = context.l10n;

    if (notification.type == 'cell_capacity_exceeded') {
      final cellId = notification.cellId?.trim();
      if (cellId == null || cellId.isEmpty) return;

      final canSplit = await _canSplitCellFromNotification(cellId);
      if (!mounted) return;

      if (!canSplit) {
        final id = notification.id;
        if (id != null) {
          await _notificationService.dismiss(id);
        }
        if (!mounted) return;
        _showMessage(l10n.notificationCellSplitNotRequired);
        return;
      }
    }

    final id = notification.id;
    if (id != null) {
      await _notificationService.dismiss(id);
    }

    if (!mounted) return;

    if (notification.type == 'cell_capacity_exceeded') {
      final cellId = notification.cellId?.trim();
      if (cellId == null || cellId.isEmpty) return;

      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => SplitCellFromCapacityScreen(
            sourceCellId: cellId,
            registeredBy: widget.session.email,
            churchId: notification.churchId,
            permissions: widget.session.permissions,
          ),
        ),
      );
    }
  }

  Future<void> _confirmDismissAll(String uid) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationsDismissAllConfirmTitle),
        content: Text(l10n.notificationsDismissAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.notificationsDismissAll),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _notificationService.dismissAllForUser(uid);
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
                final hasNotifications = (snapshot.data ?? []).isNotEmpty;
                if (!hasNotifications) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => _confirmDismissAll(uid),
                  child: Text(l10n.notificationsDismissAll),
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
