// lib/screens/alumno/checkout_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/currency_formatter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  File? _receipt;
  bool _processing = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) setState(() => _receipt = File(picked.path));
  }

  Future<void> _confirm() async {
    if (_method == PaymentMethod.transfer && _receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes subir el comprobante de pago para continuar.'),
        backgroundColor: AppColors.alertError,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
      ));
      return;
    }

    setState(() => _processing = true);
    try {
      final cart = context.read<CartProvider>();
      final auth = context.read<AuthProvider>();
      final orders = context.read<OrderProvider>();
      final products = context.read<ProductProvider>();
      final couponProvider = context.read<CouponProvider>();

      // FIX: snapshot list before async gap so cart items don't change mid-flight
      final cartItems = List.of(cart.itemList);
      final appliedCoupon = cart.appliedCoupon;

      final isSpecialOrder = cartItems.any((item) {
        final p = products.findById(item.productId);
        if (p == null) return false;
        return p.stockForSize(item.size) < item.quantity ||
            p.stockForSize(item.size) == 0;
      });

      final order = await orders.placeOrder(
        studentId: auth.currentUser!.id,
        studentName: auth.currentUser!.nombreCompleto,
        studentMatricula: auth.currentUser!.matricula,
        items: cartItems,
        subtotal: cart.subtotal,
        discount: cart.discountAmount,
        total: cart.totalAmount,
        paymentMethod: _method,
        isSpecialOrder: isSpecialOrder,
        receiptImageUrl: _receipt?.path,
        couponCode: appliedCoupon,
      );

      if (appliedCoupon != null) {
        final coupon = await couponProvider.validateCoupon(appliedCoupon);
        if (mounted && coupon != null) {
          await couponProvider.applyCouponUsage(coupon.id);
        }
      }

      for (final item in cartItems) {
        products.decrementStock(item.productId, item.size, item.quantity);
        final p = products.findById(item.productId);
        if (p != null && p.isLowStock(item.size)) {
          orders.triggerLowStockAlert(productName: p.name, size: item.size);
        }
      }

      cart.clearCart();
      if (mounted) _showSuccess(order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al procesar el pedido: $e'),
          backgroundColor: AppColors.alertError,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSuccess(Order order) {
    // FIX: use dialogContext so Navigator.pop only closes the dialog,
    // not the entire CheckoutScreen route — this was causing the red crash.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  color: AppColors.alertSuccess.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.alertSuccess, size: 44),
            ),
            const SizedBox(height: 16),
            Text('¡Pedido #${order.id} realizado!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              _method == PaymentMethod.cash
                  ? 'Tu pedido está reservado. Pasa a la papelería para liquidarlo.'
                  : _method == PaymentMethod.transfer
                      ? 'Comprobante recibido. Estamos verificando tu pago.'
                      : 'Pago procesado. La papelería preparará tu uniforme.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text('Recibirás una notificación cuando esté listo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // FIX: pop the dialog with dialogContext, then navigate
              Navigator.pop(dialogContext);
              context.go(AppRoutes.catalog);
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('Volver al catálogo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // FIX: if cart is empty (after order placed) and we're still on this screen,
    // avoid rendering an empty checkout — go_router redirect will handle it,
    // but guard here prevents a flash of empty UI.
    if (cart.isEmpty && !_processing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final needsReceipt = _method == PaymentMethod.transfer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSummary(cart),
          const SizedBox(height: 24),
          Text('Método de pago',
              style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _buildPaymentSelector(),
          if (needsReceipt) ...[
            const SizedBox(height: 20),
            _buildReceiptUploader(),
          ],
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: Container(
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
          onPressed: (!needsReceipt || _receipt != null) && !_processing
              ? _confirm
              : null,
          child: _processing
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('Confirmar Pedido'),
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del pedido',
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...cart.itemList.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                            '${item.name} (T. ${item.size}) × ${item.quantity}',
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis)),
                    Text(formatMxn(item.itemTotal),
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
              )),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.border)),
          if (cart.discountAmount > 0)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Descuento (${cart.appliedCoupon})',
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.alertSuccess,
                      fontWeight: FontWeight.w600)),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('-${formatMxn(cart.discountAmount)}',
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.alertSuccess))),
            ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('TOTAL',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatMxn(cart.totalAmount),
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary))),
          ]),
        ],
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return Column(
      children: PaymentMethod.values.map((m) {
        final sel = _method == m;
        return GestureDetector(
          onTap: () => setState(() {
            _method = m;
            _receipt = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.primary.withValues(alpha: 0.07)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border,
                  width: sel ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFor(m),
                      color: sel ? Colors.white : AppColors.textSecondary,
                      size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(m.label,
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                      Text(_descFor(m),
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                if (sel)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReceiptUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.uploadReceipt,
            style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Obligatorio para procesar tu pedido.',
            style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        if (_receipt != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_receipt!,
                height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _receipt = null),
            icon: const Icon(Icons.delete_outline, color: AppColors.alertError),
            label: const Text('Eliminar imagen',
                style: TextStyle(color: AppColors.alertError)),
          ),
        ] else
          Row(children: [
            Expanded(
                child: _PickBtn(
                    label: 'Cámara',
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _pickImage(ImageSource.camera))),
            const SizedBox(width: 12),
            Expanded(
                child: _PickBtn(
                    label: 'Galería',
                    icon: Icons.photo_outlined,
                    onTap: () => _pickImage(ImageSource.gallery))),
          ]),
      ],
    );
  }

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.transfer:
        return Icons.receipt_long_outlined;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
    }
  }

  String _descFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return 'Procesado en línea de forma inmediata.';
      case PaymentMethod.transfer:
        return 'Sube tu comprobante de OXXO o transferencia.';
      case PaymentMethod.cash:
        return 'Paga en la ventanilla de la papelería al recoger.';
    }
  }
}

class _PickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PickBtn(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
