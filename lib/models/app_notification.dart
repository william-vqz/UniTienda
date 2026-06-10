// lib/models/app_notification.dart
enum NotificationType {
  orderUpdate,
  stockAlert,
  paymentVerified,
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  bool isRead;
  final String? orderId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.orderId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'is_read': isRead ? 1 : 0,
        'order_id': orderId,
        'created_at': createdAt.toIso8601String(),
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        message: map['message'] as String,
        type: NotificationType.values.firstWhere((e) => e.name == map['type']),
        isRead: (map['is_read'] as int) == 1,
        orderId: map['order_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
