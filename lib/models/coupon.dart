class Coupon {
  final String id;
  final String code;
  final double discountPercent;
  final String description;
  final int? maxUses;
  final int usedCount;
  final bool isActive;
  final String? expiresAt;
  final String createdAt;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountPercent,
    this.description = '',
    this.maxUses,
    this.usedCount = 0,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
  });

  double get discountMultiplier => (100.0 - discountPercent) / 100.0;

  bool get isExpired {
    if (expiresAt == null) return false;
    final expiry = DateTime.tryParse(expiresAt!);
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
  }

  bool get isExhausted => maxUses != null && usedCount >= maxUses!;

  bool get isValid => isActive && !isExpired && !isExhausted;

  Coupon copyWith({
    String? id,
    String? code,
    double? discountPercent,
    String? description,
    int? maxUses,
    int? usedCount,
    bool? isActive,
    String? expiresAt,
    String? createdAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      discountPercent: discountPercent ?? this.discountPercent,
      description: description ?? this.description,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      code: json['code'] as String,
      discountPercent: (json['discount_percent'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      maxUses: json['max_uses'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      isActive: (json['is_active'] as int? ?? 1) == 1,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}
