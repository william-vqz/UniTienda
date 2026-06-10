import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/database/coupon_dao.dart';
import '../models/coupon.dart';

class CouponProvider with ChangeNotifier {
  List<Coupon> _coupons = [];
  bool _isLoading = false;

  List<Coupon> get coupons => List.unmodifiable(_coupons);
  bool get isLoading => _isLoading;

  Future<void> fetchCoupons() async {
    _isLoading = true;
    notifyListeners();

    try {
      _coupons = await CouponDao.instance.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCoupon({
    required String code,
    required double discountPercent,
    String description = '',
    int? maxUses,
    String? expiresAt,
  }) async {
    try {
      final existing = await CouponDao.instance.getByCode(code);
      if (existing != null) return false;

      final coupon = Coupon(
        id: const Uuid().v4(),
        code: code.toUpperCase(),
        discountPercent: discountPercent,
        description: description,
        maxUses: maxUses,
        expiresAt: expiresAt,
        createdAt: DateTime.now().toIso8601String(),
      );

      await CouponDao.instance.insert(coupon);
      _coupons.insert(0, coupon);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleActive(Coupon coupon) async {
    final updated = coupon.copyWith(isActive: !coupon.isActive);
    await CouponDao.instance.update(updated);
    final index = _coupons.indexWhere((c) => c.id == coupon.id);
    if (index != -1) {
      _coupons[index] = updated;
      notifyListeners();
    }
  }

  Future<bool> deleteCoupon(String id) async {
    try {
      await CouponDao.instance.delete(id);
      _coupons.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Coupon?> validateCoupon(String code) async {
    final coupon = await CouponDao.instance.getByCode(code.toUpperCase());
    if (coupon == null || !coupon.isValid) return null;
    return coupon;
  }

  Future<void> applyCouponUsage(String couponId) async {
    await CouponDao.instance.incrementUsedCount(couponId);
    final index = _coupons.indexWhere((c) => c.id == couponId);
    if (index != -1) {
      _coupons[index] =
          _coupons[index].copyWith(usedCount: _coupons[index].usedCount + 1);
      notifyListeners();
    }
  }
}
