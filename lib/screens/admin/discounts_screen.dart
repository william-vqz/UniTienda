// lib/screens/admin/discounts_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/coupon.dart';
import '../../providers/coupon_provider.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});
  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CouponProvider>().fetchCoupons();
    });
  }

  void _showAddDialog() {
    // FIX: usar showDialog con un widget StatefulWidget propio (_AddCouponDialog)
    // en lugar de StatefulBuilder con controllers sueltos.
    // Esto garantiza que los TextEditingControllers viven en el State del widget
    // y solo se disponen cuando el widget se destruye — no antes.
    showDialog(
      context: context,
      builder: (dialogCtx) => _AddCouponDialog(
        onSuccess: (code) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Cupón "$code" creado exitosamente'),
              backgroundColor: AppColors.alertSuccess,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        onError: (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.alertError,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CouponProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cupones de Descuento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo cupón',
            onPressed: _showAddDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => cp.fetchCoupons(),
          ),
        ],
      ),
      body: cp.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : cp.coupons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.discount_outlined,
                          size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text('No hay cupones registrados',
                          style: GoogleFonts.nunito(
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primer cupón'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cp.coupons.length,
                  itemBuilder: (_, i) => _CouponCard(coupon: cp.coupons[i]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Dialog como StatefulWidget propio ────────────────────────────────────────
// FIX RAÍZ: los TextEditingControllers viven en _AddCouponDialogState.
// Flutter los crea en initState() y los destruye en dispose() — nunca antes.
// Con StatefulBuilder los controllers vivían en un closure de método y Flutter
// podía reconstruir el dialog (p.ej. al abrir/cerrar el teclado) llamando
// dispose() mientras los TextFields aún los referenciaban → crash.
class _AddCouponDialog extends StatefulWidget {
  final void Function(String code) onSuccess;
  final void Function(String msg) onError;

  const _AddCouponDialog({required this.onSuccess, required this.onError});

  @override
  State<_AddCouponDialog> createState() => _AddCouponDialogState();
}

class _AddCouponDialogState extends State<_AddCouponDialog> {
  final _codeCtrl = TextEditingController();
  final _percentCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  String? _expiresAt;
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _percentCtrl.dispose();
    _descCtrl.dispose();
    _maxUsesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null && mounted) {
      setState(() {
        _expiresAt = date.toIso8601String();
        _dateCtrl.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    final percent = double.tryParse(_percentCtrl.text.trim());

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa un código para el cupón'),
        backgroundColor: AppColors.alertError,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (percent == null || percent <= 0 || percent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El descuento debe ser entre 1 y 100%'),
        backgroundColor: AppColors.alertError,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _loading = true);

    final maxUses = int.tryParse(_maxUsesCtrl.text.trim());
    final description = _descCtrl.text.trim();
    final expiresAt = _expiresAt;
    final prov = context.read<CouponProvider>();

    final success = await prov.addCoupon(
      code: code,
      discountPercent: percent,
      description: description,
      maxUses: maxUses,
      expiresAt: expiresAt,
    );

    if (!mounted) return;

    Navigator.pop(context); // cierra el dialog

    if (success) {
      widget.onSuccess(code);
    } else {
      widget.onError('Error: el código ya existe o no es válido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Nuevo Cupón'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código',
                prefixIcon: Icon(Icons.discount_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _percentCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Descuento (%)',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxUsesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Usos máximos (opcional)',
                prefixIcon: Icon(Icons.repeat),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Vencimiento (opcional)',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}

// ── Tarjeta de cupón ──────────────────────────────────────────────────────────
class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final valid = coupon.isValid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valid
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.alertError.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: valid
                    ? AppColors.alertSuccess.withValues(alpha: 0.1)
                    : AppColors.alertError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.discount,
                  color: valid ? AppColors.alertSuccess : AppColors.alertError,
                  size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(coupon.code,
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: valid
                            ? AppColors.alertSuccess.withValues(alpha: 0.15)
                            : AppColors.alertError.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${coupon.discountPercent.toStringAsFixed(0)}%',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: valid
                                ? AppColors.alertSuccess
                                : AppColors.alertError),
                      ),
                    ),
                  ]),
                  if (coupon.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(coupon.description,
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    if (coupon.maxUses != null)
                      Text('Usos: ${coupon.usedCount}/${coupon.maxUses}',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppColors.textSecondary))
                    else
                      Text('Ilimitado',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    if (coupon.expiresAt != null)
                      Text('Vence: ${coupon.expiresAt!.substring(0, 10)}',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
            Column(children: [
              Switch(
                value: coupon.isActive,
                onChanged: (_) =>
                    context.read<CouponProvider>().toggleActive(coupon),
                activeTrackColor: AppColors.alertSuccess,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.alertError, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final outerCtx = context;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar cupón'),
        content: Text('¿Eliminar el cupón ${coupon.code} de forma permanente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              outerCtx.read<CouponProvider>().deleteCoupon(coupon.id);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.alertError),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
