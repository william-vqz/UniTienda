// lib/screens/alumno/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/product_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _couponLoading = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _couponLoading = true);
    final coupon = await context.read<CouponProvider>().validateCoupon(code);
    if (!mounted) return;
    setState(() => _couponLoading = false);

    if (coupon != null) {
      context
          .read<CartProvider>()
          .applyCoupon(coupon.code, coupon.discountPercent);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '¡Cupón aplicado! ${coupon.discountPercent.toStringAsFixed(0)}% de descuento.'),
        backgroundColor: AppColors.alertSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Cupón no válido o expirado.'),
        backgroundColor: AppColors.alertError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${AppStrings.cartTitle} (${cart.totalUnits})'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop()),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: Text('Vaciar',
                  style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: cart.isEmpty ? _buildEmpty() : _buildContent(cart),
      bottomNavigationBar: cart.isEmpty ? null : _buildBottomBar(cart),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72, color: AppColors.primary.withValues(alpha: 0.20)),
          const SizedBox(height: 16),
          Text(AppStrings.cartEmpty,
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.catalog),
            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
            child: const Text('Ver catálogo'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CartProvider cart) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cart.itemList.map((item) => _CartItemTile(item: item)),
        const SizedBox(height: 20),
        _buildCouponSection(cart),
        const SizedBox(height: 20),
        _buildSummary(cart),
      ],
    );
  }

  Widget _buildCouponSection(CartProvider cart) {
    if (cart.appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.alertSuccess.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.alertSuccess.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.alertSuccess, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Cupón "${cart.appliedCoupon}" aplicado',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: AppColors.alertSuccess))),
            GestureDetector(
              onTap: () {
                cart.removeCoupon();
                _couponCtrl.clear();
              },
              child: const Icon(Icons.close,
                  size: 18, color: AppColors.alertSuccess),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _couponCtrl,
            textCapitalization: TextCapitalization.characters,
            // FIX: submit on done key
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _couponLoading ? null : _applyCoupon(),
            decoration: const InputDecoration(
              labelText: AppStrings.couponHint,
              prefixIcon:
                  Icon(Icons.local_offer_outlined, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _couponLoading ? null : _applyCoupon,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 52), padding: EdgeInsets.zero),
          child: _couponLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _buildSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: cart.subtotal),
          if (cart.discountAmount > 0)
            _SummaryRow(
                label: 'Descuento (${cart.appliedCoupon})',
                value: -cart.discountAmount,
                isDiscount: true),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.border)),
          _SummaryRow(label: 'Total', value: cart.totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.push(AppRoutes.checkout),
        child: const Text(AppStrings.btnCheckout),
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Vaciar carrito?'),
        content: const Text('Se eliminarán todos los artículos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cart.clearCart();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertError,
                minimumSize: const Size(80, 40)),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}

// ── Tile de artículo ──────────────────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    // FIX: use context.watch so this tile rebuilds when cart or products change
    final cart = context.watch<CartProvider>();
    final products = context.watch<ProductProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Miniatura
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10)),
            child: item.imageUrl.isNotEmpty
                ? ProductImage(imageUrl: item.imageUrl, borderRadius: 10)
                : const Icon(Icons.checkroom_outlined,
                    color: AppColors.textDisabled),
          ),
          const SizedBox(width: 12),

          // Nombre, talla y precio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('Talla ${item.size}',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
                const SizedBox(height: 6),
                Text(formatMxn(item.itemTotal),
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ),

          // Controles de cantidad
          Column(
            children: [
              _QtyIconBtn(
                icon: Icons.add,
                onTap: () {
                  final product = products.findById(item.productId);
                  // FIX: safe null check — product may have been deleted
                  final available = product?.stockForSize(item.size) ?? 0;
                  final effectiveMax =
                      available > 0 ? available : item.quantity + 1;
                  if (item.quantity >= effectiveMax && available > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Stock máximo alcanzado ($available unidades)'),
                      backgroundColor: AppColors.alertError,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                    return;
                  }
                  cart.addItemWithQuantity(
                    productId: item.productId,
                    name: item.name,
                    size: item.size,
                    price: item.price,
                    quantity: 1,
                    imageUrl: item.imageUrl,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${item.quantity}',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              _QtyIconBtn(
                  icon: Icons.remove,
                  onTap: () => cart.decrementItem(item.cartKey)),
            ],
          ),
          const SizedBox(width: 8),

          // Eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.alertError),
            onPressed: () => cart.removeItem(item.cartKey),
          ),
        ],
      ),
    );
  }
}

class _QtyIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Fila de resumen ───────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isDiscount;
  final bool isTotal;
  const _SummaryRow(
      {required this.label,
      required this.value,
      this.isDiscount = false,
      this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final color = isDiscount
        ? AppColors.alertSuccess
        : isTotal
            ? AppColors.primary
            : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
                  color: color)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isDiscount ? '-${formatMxn(value.abs())}' : formatMxn(value),
              style: GoogleFonts.nunito(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}
