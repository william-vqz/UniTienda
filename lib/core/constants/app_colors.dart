import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4A7BD6);
  static const Color primaryLight = Color(0xFF6B9BE8);
  static const Color primaryDark = Color(0xFF2D5AA8);

  static const Color secondary = Color(0xFF00E884);
  static const Color secondaryLight = Color(0xFF4AF0A8);
  static const Color secondaryDark = Color(0xFF00B870);

  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF252540);

  static const Color textPrimary = Color(0xFFE8ECF4);
  static const Color textSecondary = Color(0xFF9AA4B8);
  static const Color textDisabled = Color(0xFF5A6070);
  static const Color textOnDark = Color(0xFFFFFFFF);

  static const Color alertStock = Color(0xFFFF6B2B);
  static const Color alertWarning = Color(0xFFFFC107);
  static const Color alertSuccess = Color(0xFF2ECC71);
  static const Color alertError = Color(0xFFE53935);
  static const Color alertInfo = Color(0xFF2196F3);

  static const Color border = Color(0xFF3A3A50);
  static const Color borderFocus = Color(0xFF4A7BD6);
  static const Color cartBadge = Color(0xFFE53935);

  static Color get shadow => Colors.black.withValues(alpha: 0.4);
}
