// lib/core/database/order_dao.dart
//
// DAO para pedidos y sus artículos.
// Persiste el ciclo completo de vida de un pedido en SQLite.

import 'package:sqflite/sqflite.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import 'db_helper.dart';

class OrderDao {
  OrderDao._();
  static final OrderDao instance = OrderDao._();

  Future<Database> get _db async => DbHelper.instance.database;

  // ── Insertar pedido nuevo ─────────────────────────────────────────────────
  Future<void> insertOrder(Order order) async {
    final db    = await _db;
    final batch = db.batch();

    batch.insert('orders', _orderToMap(order),
        conflictAlgorithm: ConflictAlgorithm.replace);

    for (final item in order.items) {
      batch.insert('order_items', {
        'order_id':   order.id,
        'product_id': item.productId,
        'name':       item.name,
        'size':       item.size,
        'price':      item.price,
        'quantity':   item.quantity,
        'image_url':  item.imageUrl,
      });
    }

    await batch.commit(noResult: true);
  }

  // ── Actualizar estado de un pedido ────────────────────────────────────────
  Future<void> updateStatus(
    String orderId,
    OrderStatus status, {
    String? cancellationReason,
  }) async {
    final db = await _db;
    await db.update(
      'orders',
      {
        'status':               status.name,
        'updated_at':           DateTime.now().toIso8601String(),
        'cancellation_reason':  cancellationReason,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ── Obtener todos los pedidos con sus artículos ───────────────────────────
  Future<List<Order>> getAllOrders() async {
    final db         = await _db;
    final orderRows  = await db.query('orders', orderBy: 'created_at DESC');
    final orders     = <Order>[];

    for (final row in orderRows) {
      final itemRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [row['id']],
      );

      final items = itemRows.map((i) => CartItem(
        productId: i['product_id'] as String,
        name:      i['name']       as String,
        size:      i['size']       as String,
        price:     i['price']      as double,
        imageUrl:  i['image_url']  as String? ?? '',
        quantity:  i['quantity']   as int,
      )).toList();

      orders.add(_mapToOrder(row, items));
    }

    return orders;
  }

  // ── Obtener pedidos de un alumno ──────────────────────────────────────────
  Future<List<Order>> getOrdersByStudent(String studentId) async {
    final db        = await _db;
    final orderRows = await db.query(
      'orders',
      where:     'student_id = ?',
      whereArgs: [studentId],
      orderBy:   'created_at DESC',
    );

    final orders = <Order>[];
    for (final row in orderRows) {
      final itemRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [row['id']],
      );
      final items = itemRows.map((i) => CartItem(
        productId: i['product_id'] as String,
        name:      i['name']       as String,
        size:      i['size']       as String,
        price:     i['price']      as double,
        imageUrl:  i['image_url']  as String? ?? '',
        quantity:  i['quantity']   as int,
      )).toList();
      orders.add(_mapToOrder(row, items));
    }

    return orders;
  }

  // ── Helpers de serialización ──────────────────────────────────────────────
  Map<String, dynamic> _orderToMap(Order o) => {
    'id':                 o.id,
    'student_id':         o.studentId,
    'student_name':       o.studentName,
    'student_matricula':  o.studentMatricula,
    'subtotal':           o.subtotal,
    'discount':           o.discount,
    'total':              o.total,
    'payment_method':     o.paymentMethod.name,
    'receipt_image_url':  o.receiptImageUrl,
    'coupon_code':        o.couponCode,
    'status':             o.status.name,
    'cancellation_reason':o.cancellationReason,
    'created_at':         o.createdAt.toIso8601String(),
    'updated_at':         o.updatedAt.toIso8601String(),
  };

  Order _mapToOrder(Map<String, dynamic> row, List<CartItem> items) {
    return Order(
      id:                 row['id']               as String,
      studentId:          row['student_id']        as String,
      studentName:        row['student_name']       as String,
      studentMatricula:   row['student_matricula']  as String,
      subtotal:           row['subtotal']           as double,
      discount:           row['discount']           as double,
      total:              row['total']              as double,
      paymentMethod:      PaymentMethod.values.byName(row['payment_method'] as String),
      receiptImageUrl:    row['receipt_image_url']  as String?,
      couponCode:         row['coupon_code']        as String?,
      status:             OrderStatus.values.byName(row['status'] as String),
      cancellationReason: row['cancellation_reason'] as String?,
      createdAt:          DateTime.parse(row['created_at'] as String),
      updatedAt:          DateTime.parse(row['updated_at'] as String),
      items:              items,
    );
  }
}
