// lib/core/database/product_dao.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/product.dart';
import 'db_helper.dart';

class ProductDao {
  ProductDao._();
  static final ProductDao instance = ProductDao._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<void> upsertProduct(Product product) async {
    final db = await _db;
    final batch = db.batch();

    batch.insert(
      'products',
      {
        'id': product.id,
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'image_url': product.imageUrl,
        'description': product.description,
        'price_by_size': jsonEncode(product.priceBySize),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (final entry in product.stockBySize.entries) {
      batch.insert(
        'product_stock',
        {
          'product_id': product.id,
          'size': entry.key,
          'quantity': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> upsertAll(List<Product> products) async {
    for (final p in products) {
      await upsertProduct(p);
    }
  }

  Future<List<Product>> getAllProducts() async {
    final db = await _db;
    final rows = await db.query('products');
    final products = <Product>[];

    for (final row in rows) {
      final stockRows = await db.query(
        'product_stock',
        where: 'product_id = ?',
        whereArgs: [row['id']],
      );

      final stockBySize = <String, int>{};
      for (final s in stockRows) {
        stockBySize[s['size'] as String] = s['quantity'] as int;
      }

      Map<String, double> parsedPriceBySize = {};
      final pbsRaw = row['price_by_size'] as String?;
      if (pbsRaw != null && pbsRaw.isNotEmpty && pbsRaw != '{}') {
        try {
          final decoded = jsonDecode(pbsRaw) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            parsedPriceBySize[entry.key] = (entry.value as num).toDouble();
          }
        } catch (_) {}
      }

      products.add(Product(
        id: row['id'] as String,
        name: row['name'] as String,
        category: row['category'] as String,
        price: row['price'] as double,
        imageUrl: row['image_url'] as String? ?? '',
        description: row['description'] as String? ?? '',
        stockBySize: stockBySize,
        priceBySize: parsedPriceBySize,
      ));
    }

    return products;
  }

  Future<void> updateStock(String productId, String size, int newStock) async {
    final db = await _db;
    await db.insert(
      'product_stock',
      {
        'product_id': productId,
        'size': size,
        'quantity': newStock.clamp(0, 9999),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProductPrice(String productId, double newPrice) async {
    final db = await _db;
    await db.update(
      'products',
      {'price': newPrice},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> updateImageUrl(String productId, String imageUrl) async {
    final db = await _db;
    await db.update(
      'products',
      {'image_url': imageUrl},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> updateProductPriceForSize(
      String productId, String size, double newPrice) async {
    final db = await _db;
    final row = await db.query(
      'products',
      columns: ['price_by_size'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (row.isEmpty) return;

    final raw = row.first['price_by_size'] as String?;
    Map<String, double> map = {};
    if (raw != null && raw.isNotEmpty && raw != '{}') {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          map[entry.key] = (entry.value as num).toDouble();
        }
      } catch (_) {}
    }
    map[size] = newPrice;

    await db.update(
      'products',
      {'price_by_size': jsonEncode(map)},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> decrementStock(String productId, String size, int qty) async {
    final db = await _db;
    final row = await db.query(
      'product_stock',
      where: 'product_id = ? AND size = ?',
      whereArgs: [productId, size],
      limit: 1,
    );

    if (row.isEmpty) return;

    final current = row.first['quantity'] as int;
    final newStock = (current - qty).clamp(0, 9999);

    await db.update(
      'product_stock',
      {'quantity': newStock},
      where: 'product_id = ? AND size = ?',
      whereArgs: [productId, size],
    );
  }

  Future<bool> hasProducts() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    );
    return (count ?? 0) > 0;
  }

  Future<void> deleteProduct(String productId) async {
    final db = await _db;
    await db.delete('product_stock',
        where: 'product_id = ?', whereArgs: [productId]);
    await db.delete('products',
        where: 'id = ?', whereArgs: [productId]);
  }

  Future<void> updateProduct(String productId, {
    required String name,
    required String category,
    required double price,
    required String description,
    required Map<String, double> priceBySize,
  }) async {
    final db = await _db;
    await db.update(
      'products',
      {
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'price_by_size': jsonEncode(priceBySize),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
