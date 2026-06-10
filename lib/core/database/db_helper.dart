// lib/core/database/db_helper.dart
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'unitienda.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // FIX: enable foreign key enforcement so ON DELETE CASCADE actually works
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE users (
        id              TEXT PRIMARY KEY,
        nombre_completo TEXT NOT NULL,
        matricula       TEXT NOT NULL UNIQUE,
        grado           TEXT NOT NULL,
        grupo           TEXT NOT NULL,
        email           TEXT NOT NULL UNIQUE,
        telefono        TEXT NOT NULL,
        password        TEXT NOT NULL,
        profile_image   TEXT DEFAULT '',
        role            TEXT NOT NULL,
        created_at      TEXT NOT NULL
      )
    ''');

    // FIX: added index on category for faster byCategory() queries
    batch.execute('''
      CREATE TABLE products (
        id            TEXT PRIMARY KEY,
        name          TEXT NOT NULL,
        category      TEXT NOT NULL,
        price         REAL NOT NULL,
        image_url     TEXT DEFAULT '',
        description   TEXT DEFAULT '',
        price_by_size TEXT DEFAULT '{}'
      )
    ''');

    batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');

    batch.execute('''
      CREATE TABLE product_stock (
        product_id  TEXT NOT NULL,
        size        TEXT NOT NULL,
        quantity    INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (product_id, size),
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE orders (
        id                  TEXT PRIMARY KEY,
        student_id          TEXT NOT NULL,
        student_name        TEXT NOT NULL,
        student_matricula   TEXT NOT NULL,
        subtotal            REAL NOT NULL,
        discount            REAL NOT NULL DEFAULT 0,
        total               REAL NOT NULL,
        payment_method      TEXT NOT NULL,
        receipt_image_url   TEXT,
        coupon_code         TEXT,
        status              TEXT NOT NULL,
        cancellation_reason TEXT,
        created_at          TEXT NOT NULL,
        updated_at          TEXT NOT NULL
      )
    ''');

    // FIX: index on student_id so ordersForStudent() is O(log n) not O(n)
    batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_orders_student ON orders(student_id)');
    batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status)');

    batch.execute('''
      CREATE TABLE order_items (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id    TEXT NOT NULL,
        product_id  TEXT NOT NULL,
        name        TEXT NOT NULL,
        size        TEXT NOT NULL,
        price       REAL NOT NULL,
        quantity    INTEGER NOT NULL,
        image_url   TEXT DEFAULT '',
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE notifications (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL,
        title       TEXT NOT NULL,
        message     TEXT NOT NULL,
        type        TEXT NOT NULL,
        is_read     INTEGER NOT NULL DEFAULT 0,
        order_id    TEXT,
        created_at  TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // FIX: index for fetchNotifications(userId)
    batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id)');

    batch.execute('''
      CREATE TABLE coupons (
        id              TEXT PRIMARY KEY,
        code            TEXT NOT NULL UNIQUE,
        discount_percent REAL NOT NULL,
        description     TEXT DEFAULT '',
        max_uses        INTEGER,
        used_count      INTEGER NOT NULL DEFAULT 0,
        is_active       INTEGER NOT NULL DEFAULT 1,
        expires_at      TEXT,
        created_at      TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute(
            'ALTER TABLE users ADD COLUMN profile_image TEXT DEFAULT ""');
      } catch (e) {
        debugPrint('Migration v3 ignored: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
            'ALTER TABLE products ADD COLUMN price_by_size TEXT DEFAULT "{}"');
      } catch (e) {
        debugPrint('Migration v4 ignored: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS coupons (
            id              TEXT PRIMARY KEY,
            code            TEXT NOT NULL UNIQUE,
            discount_percent REAL NOT NULL,
            description     TEXT DEFAULT '',
            max_uses        INTEGER,
            used_count      INTEGER NOT NULL DEFAULT 0,
            is_active       INTEGER NOT NULL DEFAULT 1,
            expires_at      TEXT,
            created_at      TEXT NOT NULL
          )
        ''');
      } catch (e) {
        debugPrint('Migration v5 ignored: $e');
      }
    }
    // FIX: add indexes if upgrading (safe with IF NOT EXISTS)
    try {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_orders_student ON orders(student_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id)');
    } catch (e) {
      debugPrint('Index migration ignored: $e');
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }
}
