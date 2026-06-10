// lib/screens/alumno/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().findById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: const Center(child: Text('Producto no encontrado.')),
      );
    }

    final stock        = _selectedSize != null ? product.stockForSize(_selectedSize!) : 0;
    final isLow        = _selectedSize != null && product.isLowStock(_selectedSize!);
    final exceedsStock = _selectedSize != null && _quantity > stock;
    final noStock      = _selectedSize != null && stock == 0;
    final displayPrice = _selectedSize != null ? product.priceForSize(_selectedSize!) : product.price;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-image-${product.id}',
                child: Container(
                  color: AppColors.surfaceVariant,
                  child: ProductImage(imageUrl: product.imageUrl),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(),
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(product.name,
                    style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(fit: BoxFit.scaleDown, child: Text(formatMxn(displayPrice),
                    style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(product.description,
                      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Selector de talla
                  Text('Selecciona tu talla',
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildSizeSelector(product),
                  const SizedBox(height: 16),

                  if (_selectedSize != null) ...[
                    _buildStockInfo(stock, isLow),
                    const SizedBox(height: 14),
                    _buildQuantitySelector(stock),
                    const SizedBox(height: 14),
                  ],

                  if (exceedsStock && !noStock) _buildAlertBanner(stock),
                  if (noStock) _buildNoStockBanner(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(product, exceedsStock, noStock),
    );
  }

  Widget _buildSizeSelector(Product product) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: Product.standardSizes.map((size) {
        final s        = product.stockForSize(size);
        final selected = _selectedSize == size;
        final empty    = s == 0;
        return GestureDetector(
          onTap: () => setState(() { _selectedSize = size; _quantity = 1; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 60, height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : empty ? AppColors.surfaceVariant.withValues(alpha: 0.5) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
            ),
            child: Center(
              child: Text(size,
                style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : empty ? AppColors.textDisabled : AppColors.textPrimary,
                  decoration: empty ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStockInfo(int stock, bool isLow) {
    return Row(
      children: [
        Icon(isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
          size: 16, color: isLow ? AppColors.alertStock : AppColors.secondary),
        const SizedBox(width: 6),
        Text(
          isLow ? 'Solo quedan $stock piezas disponibles' : 'En stock: $stock piezas',
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600,
            color: isLow ? AppColors.alertStock : AppColors.secondary),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(int stock) {
    final maxQty = stock > 0 ? stock + 99 : 99;
    return Row(
      children: [
        Text('Cantidad:',
          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(width: 16),
        _QtyBtn(icon: Icons.remove, onTap: _quantity > 1 ? () => setState(() => _quantity--) : null),
        const SizedBox(width: 12),
        Text('$_quantity',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(width: 12),
        _QtyBtn(icon: Icons.add, onTap: _quantity < maxQty ? () => setState(() => _quantity++) : null),
      ],
    );
  }

  Widget _buildAlertBanner(int available) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertStock.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertStock.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.alertStock, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(AppStrings.stockAlertBanner(remaining: available),
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.alertStock, fontWeight: FontWeight.w600, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoStockBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: AppColors.alertError, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(AppStrings.noStockMessage,
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.alertError, fontWeight: FontWeight.w600, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Product product, bool exceedsStock, bool noStock) {
    final canAdd = _selectedSize != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: ElevatedButton.icon(
        onPressed: canAdd ? () => _addToCart(product, exceedsStock) : null,
        icon: Icon(noStock ? Icons.schedule_outlined : Icons.add_shopping_cart_outlined, size: 20),
        label: Text(
          !canAdd        ? 'Selecciona una talla'
          : noStock      ? 'Agregar como Pedido Especial'
          : exceedsStock ? 'Agregar ($_quantity) — incluye Pedido Especial'
                         : 'Agregar al carrito ($_quantity)',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: (noStock || exceedsStock) ? AppColors.alertStock : AppColors.primary,
          disabledBackgroundColor: AppColors.border,
        ),
      ),
    );
  }

  void _addToCart(Product product, bool exceedsStock) {
    final cart = context.read<CartProvider>();
    final sizePrice = product.priceForSize(_selectedSize!);
    try {
      if (exceedsStock) {
        cart.addItemWithQuantity(
          productId: product.id, name: product.name, size: _selectedSize!,
          price: sizePrice, quantity: _quantity, imageUrl: product.imageUrl,
        );
      } else {
        for (var i = 0; i < _quantity; i++) {
          cart.addItem(
            productId: product.id, name: product.name, size: _selectedSize!,
            price: sizePrice, availableStock: product.stockForSize(_selectedSize!),
            imageUrl: product.imageUrl,
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${product.name} ($_selectedSize) agregado al carrito.'),
        backgroundColor: AppColors.alertSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Ver carrito', textColor: Colors.white,
          onPressed: () => context.push(AppRoutes.cart),
        ),
      ));
    } on CartException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppColors.alertError,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceVariant : AppColors.surfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? AppColors.textPrimary : AppColors.textDisabled),
      ),
    );
  }
}
