// lib/providers/cart_provider.dart
// Motor O(1) del carrito — Spec §3
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

// ── Excepción tipada ──────────────────────────────────────────────────────────
enum CartExceptionType { insufficientStock, noStock }

class CartException implements Exception {
  final String message;
  final CartExceptionType type;
  const CartException(this.message, this.type);
  @override
  String toString() => message;
}

// ── CartProvider ──────────────────────────────────────────────────────────────
class CartProvider with ChangeNotifier {

  // Mapa indexado por clave compuesta "${productId}_$size" — O(1)
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items    => {..._items};
  List<CartItem> get itemList        => _items.values.toList();
  int  get itemCount                 => _items.length;
  int  get totalUnits                => _items.values.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty                   => _items.isEmpty;

  String? _appliedCoupon;
  double? _appliedDiscountPercent;

  double get subtotal        => _items.values.fold(0.0, (s, i) => s + i.itemTotal);
  double get discountAmount  {
    if (_appliedDiscountPercent == null) return 0.0;
    return subtotal * (_appliedDiscountPercent! / 100.0);
  }
  double get totalAmount     => (subtotal - discountAmount).clamp(0.0, double.infinity);

  // ── Agregar — Spec §3 ────────────────────────────────────────────────────
  void addItem({
    required String productId,
    required String name,
    required String size,
    required double price,
    required int availableStock,
    String imageUrl = '',
  }) {
    final key = '${productId}_$size';

    if (_items.containsKey(key)) {
      final existing    = _items[key]!;
      final newQuantity = existing.quantity + 1;
      if (newQuantity > availableStock) {
        throw CartException(
          'Stock insuficiente. Disponibles: $availableStock, en carrito: ${existing.quantity}.',
          CartExceptionType.insufficientStock,
        );
      }
      _items[key] = existing.copyWith(quantity: newQuantity);
    } else {
      if (availableStock < 1) {
        throw const CartException(
          'Sin stock físico. Requiere Pedido Especial de Fábrica.',
          CartExceptionType.noStock,
        );
      }
      _items[key] = CartItem(
        productId: productId,
        name:      name,
        size:      size,
        price:     price,
        imageUrl:  imageUrl,
        quantity:  1,
      );
    }
    notifyListeners();
  }

  // ── Agregar con cantidad específica (Pedido Especial) ────────────────────
  void addItemWithQuantity({
    required String productId,
    required String name,
    required String size,
    required double price,
    required int quantity,
    String imageUrl = '',
  }) {
    assert(quantity > 0, 'La cantidad debe ser mayor a cero');
    final key = '${productId}_$size';
    if (_items.containsKey(key)) {
      final existing = _items[key]!;
      _items[key] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _items[key] = CartItem(
        productId: productId,
        name:      name,
        size:      size,
        price:     price,
        imageUrl:  imageUrl,
        quantity:  quantity,
      );
    }
    notifyListeners();
  }

  // ── Reducir cantidad ──────────────────────────────────────────────────────
  void decrementItem(String cartKey) {
    if (!_items.containsKey(cartKey)) return;
    final item = _items[cartKey]!;
    if (item.quantity <= 1) {
      _items.remove(cartKey);
    } else {
      _items[cartKey] = item.copyWith(quantity: item.quantity - 1);
    }
    notifyListeners();
  }

  // ── Eliminar — Spec §3 ────────────────────────────────────────────────────
  void removeItem(String cartKey) {
    if (_items.remove(cartKey) != null) notifyListeners();
  }

  // ── Vaciar — Spec §3 ──────────────────────────────────────────────────────
  void clearCart() {
    _items.clear();
    _appliedCoupon  = null;
    _appliedDiscountPercent = null;
    notifyListeners();
  }

  String? get appliedCoupon => _appliedCoupon;
  double? get appliedDiscountPercent => _appliedDiscountPercent;

  void applyCoupon(String code, double discountPercent) {
    _appliedCoupon = code.toUpperCase();
    _appliedDiscountPercent = discountPercent;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _appliedDiscountPercent = null;
    notifyListeners();
  }

  // ── Helpers para la UI ────────────────────────────────────────────────────
  bool containsKey(String cartKey) => _items.containsKey(cartKey);
  int  quantityOf(String cartKey)  => _items[cartKey]?.quantity ?? 0;
}
