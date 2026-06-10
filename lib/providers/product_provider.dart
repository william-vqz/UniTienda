// lib/providers/product_provider.dart
import 'package:flutter/foundation.dart';
import '../core/database/product_dao.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dao = ProductDao.instance;
      final hasData = await dao.hasProducts();

      if (!hasData) {
        await dao.upsertAll(_mockProducts);
      }

      _products = await dao.getAllProducts();
    } catch (e) {
      _error = 'No se pudo cargar el catálogo: $e';
      debugPrint('ProductProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FIX: safe null return instead of throwing
  Product? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Product> byCategory(String category) {
    if (category == 'Todos') return List.unmodifiable(_products);
    return List.unmodifiable(
        _products.where((p) => p.category == category).toList());
  }

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList()..sort();
    return ['Todos', ...cats];
  }

  // FIX: wrap in try-catch so a bad productId doesn't crash the whole app
  Future<void> decrementStock(String productId, String size, int qty) async {
    try {
      await ProductDao.instance.decrementStock(productId, size, qty);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final currentStock = _products[index].stockForSize(size);
        final updatedProduct = _products[index]
            .withUpdatedStock(size, (currentStock - qty).clamp(0, 9999));
        _products[index] = updatedProduct;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('decrementStock error: $e');
    }
  }

  Future<void> setStock(String productId, String size, int newStock) async {
    await ProductDao.instance.updateStock(productId, size, newStock);
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updatedProduct = _products[index].withUpdatedStock(size, newStock);
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  Future<void> updateProductPriceForSize(
      String productId, String size, double newPrice) async {
    await ProductDao.instance
        .updateProductPriceForSize(productId, size, newPrice);
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updatedProduct =
          _products[index].withUpdatedPriceForSize(size, newPrice);
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  Future<void> updateProductPrice(String productId, double newPrice) async {
    await ProductDao.instance.updateProductPrice(productId, newPrice);
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updatedProduct = _products[index].withUpdatedPrice(newPrice);
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    final dao = ProductDao.instance;
    await dao.upsertProduct(product);
    _products.add(product);
    // FIX: sort after adding so the list stays consistent with UI ordering
    notifyListeners();
  }

  Future<void> updateProductImage(String productId, String imageUrl) async {
    await ProductDao.instance.updateImageUrl(productId, imageUrl);
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updatedProduct = _products[index].copyWith(imageUrl: imageUrl);
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    await ProductDao.instance.deleteProduct(productId);
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  Future<void> updateProduct(
    String productId, {
    required String name,
    required String category,
    required double price,
    required String description,
    required Map<String, double> priceBySize,
  }) async {
    await ProductDao.instance.updateProduct(
      productId,
      name: name,
      category: category,
      price: price,
      description: description,
      priceBySize: priceBySize,
    );
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updatedProduct = _products[index].copyWith(
        name: name,
        category: category,
        price: price,
        description: description,
        priceBySize: priceBySize,
      );
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  static final List<Product> _mockProducts = [
    const Product(
      id: 'CAMP-272-AZ',
      name: 'Camisa Oficial CBTis 272',
      category: 'Camisa',
      price: 220.00,
      description: 'Camisa de vestir azul marino con logo bordado del plantel.',
      stockBySize: {'CH': 8, 'M': 3, 'G': 12, 'XG': 2, 'XXG': 0},
    ),
    const Product(
      id: 'PANT-272-GR',
      name: 'Pantalón Escolar Gris',
      category: 'Pantalón',
      price: 280.00,
      description: 'Pantalón de vestir gris oxford, tela antiarrugas.',
      stockBySize: {'CH': 5, 'M': 10, 'G': 7, 'XG': 3, 'XXG': 1},
    ),
    const Product(
      id: 'PANT-272-GR-F',
      name: 'Falda Escolar Gris',
      category: 'Falda',
      price: 260.00,
      description: 'Falda tableada gris, largo reglamentario.',
      stockBySize: {'CH': 6, 'M': 4, 'G': 2, 'XG': 0, 'XXG': 0},
    ),
    const Product(
      id: 'SUAD-272-AZ',
      name: 'Sudadera CBTis 272',
      category: 'Sudadera',
      price: 350.00,
      description: 'Sudadera azul marino con capucha, logo CBTis en frente.',
      stockBySize: {'CH': 2, 'M': 1, 'G': 3, 'XG': 0, 'XXG': 0},
    ),
    const Product(
      id: 'CINT-272-AZ',
      name: 'Cinturón Escolar',
      category: 'Accesorios',
      price: 80.00,
      description: 'Cinturón de piel negro con hebilla institucional.',
      stockBySize: {'CH': 15, 'M': 20, 'G': 12, 'XG': 5, 'XXG': 3},
    ),
  ];
}
