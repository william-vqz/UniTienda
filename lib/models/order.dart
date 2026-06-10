// lib/models/order.dart
import 'cart_item.dart';

enum OrderStatus {
  pendingPayment,
  paymentReview,
  confirmed,
  specialOrder,
  readyForPickup,
  delivered,
  cancelled,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Pago Pendiente';
      case OrderStatus.paymentReview:
        return 'Verificando Pago';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.specialOrder:
        return 'Pedido Especial';
      case OrderStatus.readyForPickup:
        return 'Listo para Recoger';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}

enum PaymentMethod { card, transfer, cash }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return 'Tarjeta / Digital';
      case PaymentMethod.transfer:
        return 'OXXO / Transferencia';
      case PaymentMethod.cash:
        return 'Efectivo en Ventanilla';
    }
  }

  bool get requiresReceiptUpload => this == PaymentMethod.transfer;
}

class Order {
  final String id;
  final String studentId;
  final String studentName;
  final String studentMatricula;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final String? receiptImageUrl;
  final String? couponCode;
  final DateTime createdAt;
  OrderStatus status;
  DateTime updatedAt;
  String? cancellationReason;

  Order({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentMatricula,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    this.receiptImageUrl,
    this.couponCode,
    this.status = OrderStatus.pendingPayment,
    this.cancellationReason,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isSpecialOrder => status == OrderStatus.specialOrder;
  bool get isFinalStatus => isCancelled || isDelivered;

  void updateStatus(OrderStatus newStatus, {String? cancelReason}) {
    status = newStatus;
    updatedAt = DateTime.now();
    if (newStatus == OrderStatus.cancelled) {
      cancellationReason = cancelReason;
    }
  }
}
