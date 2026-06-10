// lib/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../models/app_notification.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => [..._notifications];
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;

  Future<Database> get _db async => DbHelper.instance.database;

  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _db;
      final result = await db.query(
        'notifications',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      _notifications = result.map((r) => AppNotification.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? orderId,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      orderId: orderId,
    );

    final db = await _db;
    await db.insert('notifications', notification.toMap());

    _notifications.insert(0, notification);
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final db = await _db;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final db = await _db;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );

    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    final db = await _db;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );

    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }
}
