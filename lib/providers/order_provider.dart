// lib/providers/order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/order_dao.dart';
import '../core/constants/app_strings.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/app_notification.dart';
import 'notification_provider.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  NotificationProvider? _notificationProvider;

  List<Order> get orders => [..._orders];
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Order> get completedOrders =>
      _orders.where((o) => o.isDelivered || o.isCancelled).toList();

  List<Order> get activeOrders =>
      _orders.where((o) => !o.isFinalStatus).toList();

  List<Order> ordersForStudent(String studentId) =>
      _orders.where((o) => o.studentId == studentId).toList();

  List<Order> ordersByStatus(OrderStatus status) =>
      _orders.where((o) => o.status == status).toList();

  List<Order> get pendingOrders =>
      _orders.where((o) => !o.isFinalStatus).toList();

  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await OrderDao.instance.getAllOrders();
    } catch (e) {
      _error = 'Error cargando pedidos: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order> placeOrder({
    required String studentId,
    required String studentName,
    required String studentMatricula,
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double total,
    required PaymentMethod paymentMethod,
    required bool isSpecialOrder,
    String? receiptImageUrl,
    String? couponCode,
  }) async {
    // FIX: don't set _isLoading=true here — it triggers a rebuild that can
    // cause context.read calls in checkout to fail mid-flight.
    try {
      OrderStatus status;
      if (isSpecialOrder) {
        status = OrderStatus.specialOrder;
      } else {
        status = receiptImageUrl != null
            ? OrderStatus.paymentReview
            : OrderStatus.pendingPayment;
      }
      final order = Order(
        id: const Uuid().v4().substring(0, 8).toUpperCase(),
        studentId: studentId,
        studentName: studentName,
        studentMatricula: studentMatricula,
        items: List.from(items),
        subtotal: subtotal,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        receiptImageUrl: receiptImageUrl,
        couponCode: couponCode,
        createdAt: DateTime.now(),
        status: status,
      );

      await OrderDao.instance.insertOrder(order);
      _orders.insert(0, order);
      notifyListeners();

      _sendPushToAdmin(
        AppStrings.pushAdminNewOrder(studentName: studentName),
      );

      return order;
    } catch (e) {
      debugPrint('Error placing order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? cancelReason,
  }) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i == -1) return;

    await OrderDao.instance.updateStatus(
      orderId,
      newStatus,
      cancellationReason: cancelReason,
    );

    _orders[i].updateStatus(newStatus, cancelReason: cancelReason);
    notifyListeners();

    final order = _orders[i];

    switch (newStatus) {
      case OrderStatus.readyForPickup:
        _sendPushToStudent(
          order.studentId,
          AppStrings.pushAlumnoReadyPickup,
          title: 'Pedido listo',
          type: NotificationType.orderUpdate,
          orderId: orderId,
        );
        break;
      case OrderStatus.specialOrder:
        _sendPushToStudent(
          order.studentId,
          AppStrings.pushAlumnoOrderConfirmed,
          title: 'Pedido confirmado',
          type: NotificationType.orderUpdate,
          orderId: orderId,
        );
        break;
      case OrderStatus.cancelled:
        _sendPushToStudent(
          order.studentId,
          AppStrings.pushAlumnoCancelled(
            reason: cancelReason ?? 'motivo no especificado',
          ),
          title: 'Pedido cancelado',
          type: NotificationType.orderUpdate,
          orderId: orderId,
        );
        break;
      case OrderStatus.confirmed:
        _sendPushToStudent(
          order.studentId,
          'Tu pago ha sido verificado. Estamos preparando tu pedido.',
          title: 'Pago verificado',
          type: NotificationType.paymentVerified,
          orderId: orderId,
        );
        break;
      default:
        break;
    }
  }

  void triggerLowStockAlert(
      {required String productName, required String size}) {
    _sendPushToAdmin(
      AppStrings.pushAdminLowStock(productName: productName, size: size),
    );
  }

  // FIX: refresh orders list from DB to ensure UI stays in sync
  Future<void> refreshOrders() async {
    try {
      _orders = await OrderDao.instance.getAllOrders();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing orders: $e');
    }
  }

  void _sendPushToAdmin(String message) {
    debugPrint('[PUSH → ADMIN] $message');
  }

  void _sendPushToStudent(
    String studentId,
    String message, {
    String title = 'UniTienda',
    NotificationType type = NotificationType.general,
    String? orderId,
  }) async {
    debugPrint('[PUSH → ALUMNO $studentId] $message');

    if (_notificationProvider != null) {
      await _notificationProvider!.addNotification(
        userId: studentId,
        title: title,
        message: message,
        type: type,
        orderId: orderId,
      );
    }
  }
}
