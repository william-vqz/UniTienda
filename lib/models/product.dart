import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String description;
  final Map<String, int> stockBySize;
  final Map<String, double> priceBySize;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stockBySize,
    this.imageUrl = '',
    this.description = '',
    this.priceBySize = const {},
  });

  int stockForSize(String size) => stockBySize[size] ?? 0;
  bool hasStockForSize(String size) => stockForSize(size) > 0;

  double priceForSize(String size) => priceBySize[size] ?? price;

  bool isLowStock(String size) {
    final s = stockForSize(size);
    return s > 0 && s <= 3;
  }

  List<String> get availableSizes =>
      stockBySize.keys.where((s) => stockBySize[s]! > 0).toList();

  bool get hasAnyStock => availableSizes.isNotEmpty;

  static const List<String> standardSizes = ['CH', 'M', 'G', 'XG', 'XXG'];

  factory Product.fromJson(Map<String, dynamic> json) {
    Map<String, double> parsedPriceBySize = {};
    if (json['precio_por_talla'] != null) {
      if (json['precio_por_talla'] is String) {
        final decoded = jsonDecode(json['precio_por_talla'] as String);
        for (final entry in (decoded as Map<String, dynamic>).entries) {
          parsedPriceBySize[entry.key] = (entry.value as num).toDouble();
        }
      } else if (json['precio_por_talla'] is Map) {
        for (final entry in (json['precio_por_talla'] as Map<String, dynamic>).entries) {
          parsedPriceBySize[entry.key] = (entry.value as num).toDouble();
        }
      }
    }
    return Product(
      id: json['id'] as String,
      name: json['nombre'] as String,
      category: json['categoria'] as String,
      price: (json['precio'] as num).toDouble(),
      imageUrl: json['imagen_url'] as String? ?? '',
      description: json['descripcion'] as String? ?? '',
      stockBySize: Map<String, int>.from(json['stock_por_talla'] as Map),
      priceBySize: parsedPriceBySize,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? imageUrl,
    String? description,
    Map<String, int>? stockBySize,
    Map<String, double>? priceBySize,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      stockBySize: stockBySize ?? Map<String, int>.from(this.stockBySize),
      priceBySize: priceBySize ?? Map<String, double>.from(this.priceBySize),
    );
  }

  Product withUpdatedStock(String size, int newStock) {
    final updated = Map<String, int>.from(stockBySize);
    updated[size] = newStock.clamp(0, 9999);
    return copyWith(stockBySize: updated);
  }

  Product withUpdatedPrice(double newPrice) {
    return copyWith(price: newPrice);
  }

  Product withUpdatedPriceForSize(String size, double newPrice) {
    final updated = Map<String, double>.from(priceBySize);
    updated[size] = newPrice;
    return copyWith(priceBySize: updated);
  }
}
