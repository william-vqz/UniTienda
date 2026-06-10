// lib/screens/alumno/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAlumno) {
        context.read<NotificationProvider>().fetchNotifications(auth.studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.notificationsTitle),
        actions: [
          if (notif.unreadCount > 0)
            TextButton.icon(
              onPressed: () => notif.markAllAsRead(auth.studentId),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text(AppStrings.markAllRead),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: notif.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : notif.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none_outlined,
                          size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(AppStrings.noNotifications,
                          style: GoogleFonts.nunito(
                              fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notif.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NotificationTile(
                    notification: notif.notifications[i],
                    onTap: () => notif.markAsRead(notif.notifications[i].id),
                    onDelete: () =>
                        notif.deleteNotification(notif.notifications[i].id),
                  ),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.receipt_long_outlined;
      case NotificationType.stockAlert:
        return Icons.warning_amber_outlined;
      case NotificationType.paymentVerified:
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return AppColors.primary;
      case NotificationType.stockAlert:
        return AppColors.alertStock;
      case NotificationType.paymentVerified:
        return AppColors.alertSuccess;
      default:
        return AppColors.secondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : _getColor(notification.type).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getColor(notification.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(notification.type),
                  color: _getColor(notification.type), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(_formatDate(notification.createdAt),
                          style: GoogleFonts.nunito(
                              fontSize: 10, color: AppColors.textDisabled)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getColor(notification.type),
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close,
                  size: 18, color: AppColors.textDisabled),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
