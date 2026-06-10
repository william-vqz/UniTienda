import 'package:sqflite/sqflite.dart';
import '../../models/coupon.dart';
import 'db_helper.dart';

class CouponDao {
  CouponDao._();
  static final CouponDao instance = CouponDao._();

  Future<Database> get _db async => DbHelper.instance.database;

  Future<void> insert(Coupon coupon) async {
    final db = await _db;
    await db.insert('coupons', {
      'id': coupon.id,
      'code': coupon.code,
      'discount_percent': coupon.discountPercent,
      'description': coupon.description,
      'max_uses': coupon.maxUses,
      'used_count': coupon.usedCount,
      'is_active': coupon.isActive ? 1 : 0,
      'expires_at': coupon.expiresAt,
      'created_at': coupon.createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Coupon>> getAll() async {
    final db = await _db;
    final rows = await db.query('coupons', orderBy: 'created_at DESC');
    return rows.map((r) => Coupon.fromJson(r)).toList();
  }

  Future<Coupon?> getByCode(String code) async {
    final db = await _db;
    final rows = await db.query('coupons',
        where: 'code = ?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) return null;
    return Coupon.fromJson(rows.first);
  }

  Future<void> update(Coupon coupon) async {
    final db = await _db;
    await db.update(
      'coupons',
      {
        'code': coupon.code,
        'discount_percent': coupon.discountPercent,
        'description': coupon.description,
        'max_uses': coupon.maxUses,
        'used_count': coupon.usedCount,
        'is_active': coupon.isActive ? 1 : 0,
        'expires_at': coupon.expiresAt,
      },
      where: 'id = ?',
      whereArgs: [coupon.id],
    );
  }

  Future<void> incrementUsedCount(String couponId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE coupons SET used_count = used_count + 1 WHERE id = ?',
      [couponId],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('coupons', where: 'id = ?', whereArgs: [id]);
  }
}
