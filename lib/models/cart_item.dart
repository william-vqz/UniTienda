// lib/models/cart_item.dart
// Modelo inmutable — Spec §2.2
class CartItem {
  final String productId;
  final String name;
  final String size;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.size,
    required this.price,
    this.imageUrl = '',
    this.quantity = 1,
  });

  /// Clave compuesta — Spec §2.1: "PROD-001_M"
  String get cartKey => '${productId}_$size';

  double get itemTotal => price * quantity;

  /// Clonar respetando patrones reactivos — Spec §2.2
  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name:      name,
        size:      size,
        price:     price,
        imageUrl:  imageUrl,
        quantity:  quantity ?? this.quantity,
      );

  @override
  String toString() =>
      'CartItem(key: $cartKey, qty: $quantity, total: \$${itemTotal.toStringAsFixed(2)})';
}
