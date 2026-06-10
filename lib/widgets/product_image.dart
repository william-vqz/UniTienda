import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
  });

  Widget _placeholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.image_outlined,
            size: 32, color: AppColors.textDisabled),
      );

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _placeholder();

    final image = imageUrl.startsWith('http')
        ? Image.network(imageUrl, fit: fit, errorBuilder: (_, __, ___) => _placeholder())
        : Image.file(File(imageUrl), fit: fit, errorBuilder: (_, __, ___) => _placeholder());

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }
    return image;
  }
}
