// lib/screens/admin/orders_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../core/database/user_dao.dart';
import '../../models/app_user.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/slide_fade_in.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _tabLabels = [
    'Activos',
    'Completados',
    'Por verificar',
    'Confirmados',
    'Especiales',
    'Listos'
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<Order> _filter(List<Order> all, int i) {
    switch (i) {
      case 0:
        return all.where((o) => !o.isFinalStatus).toList();
      case 1:
        return all.where((o) => o.isDelivered || o.isCancelled).toList();
      case 2:
        return all
            .where((o) =>
                o.status == OrderStatus.pendingPayment ||
                o.status == OrderStatus.paymentReview)
            .toList();
      case 3:
        return all.where((o) => o.status == OrderStatus.confirmed).toList();
      case 4:
        return all.where((o) => o.status == OrderStatus.specialOrder).toList();
      case 5:
        return all
            .where((o) => o.status == OrderStatus.readyForPickup)
            .toList();
      default:
        return all.where((o) => !o.isFinalStatus).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: _tabLabels.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: List.generate(_tabLabels.length, (i) {
          final list = _filter(orders.orders, i);
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 52, color: AppColors.textDisabled),
                  const SizedBox(height: 12),
                  Text('No hay pedidos en esta categoría',
                      style:
                          GoogleFonts.nunito(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, idx) =>
                SlideFadeIn(index: idx, child: _OrderCard(order: list[idx])),
          );
        }),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  AppUser? _userInfo;
  bool _loadingUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _loadingUser = true);
    final user = await UserDao.instance.getUserById(widget.order.studentId);
    if (mounted) {
      setState(() {
        _userInfo = user;
        _loadingUser = false;
      });
    }
  }

  Color getStatusColor() {
    switch (widget.order.status) {
      case OrderStatus.pendingPayment:
        return AppColors.alertWarning;
      case OrderStatus.paymentReview:
        return AppColors.alertInfo;
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.specialOrder:
        return AppColors.alertInfo;
      case OrderStatus.readyForPickup:
        return AppColors.alertSuccess;
      case OrderStatus.delivered:
        return AppColors.secondary;
      case OrderStatus.cancelled:
        return AppColors.alertError;
    }
  }

  String getStatusText() {
    switch (widget.order.status) {
      case OrderStatus.pendingPayment:
        return 'Pago Pendiente';
      case OrderStatus.paymentReview:
        return 'Verificando Pago';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.specialOrder:
        return 'Pedido Especial';
      case OrderStatus.readyForPickup:
        return 'Listo para Recoger';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  void _showReceipt() {
    final url = widget.order.receiptImageUrl;
    if (url == null || url.isEmpty) return;
    // FIX: use dialogContext to close dialog — not outer context
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: url.startsWith('http')
                    ? Image.network(url, fit: BoxFit.contain)
                    : Image.file(
                        File(url),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_not_supported,
                                size: 64, color: Colors.white54),
                            const SizedBox(height: 12),
                            Text('No se pudo cargar la imagen',
                                style:
                                    GoogleFonts.nunito(color: Colors.white70)),
                          ],
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                // FIX: pop with dialogCtx
                onPressed: () => Navigator.of(dialogCtx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor();
    final statusText = getStatusText();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText,
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                const Spacer(),
                Text('#${widget.order.id}',
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        '${widget.order.studentName} · ${widget.order.studentMatricula}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ),
                ]),
                const SizedBox(height: 6),
                if (_loadingUser)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_userInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.school_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                                '${_userInfo!.grado}° · Grupo ${_userInfo!.grupo}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textPrimary)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.email_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_userInfo!.email,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textPrimary)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.phone_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_userInfo!.telefono,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textPrimary)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ...widget.order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                          '• ${item.name} (Talla ${item.size}) x${item.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              fontSize: 13, color: AppColors.textSecondary)),
                    )),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(_iconForPayment(widget.order.paymentMethod),
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(widget.order.paymentMethod.label,
                            style: GoogleFonts.nunito(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(formatMxn(widget.order.total),
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary)),
                      ),
                    ]),
              ],
            ),
          ),
          if (widget.order.status == OrderStatus.paymentReview &&
              widget.order.receiptImageUrl != null &&
              widget.order.receiptImageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: GestureDetector(
                onTap: _showReceipt,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.alertWarning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.alertWarning.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.receipt_outlined,
                        size: 16, color: AppColors.alertWarning),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Comprobante cargado. Toca para ver.',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.alertWarning,
                                fontWeight: FontWeight.w600))),
                  ]),
                ),
              ),
            ),
          if (!widget.order.isFinalStatus)
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildActions(context),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final prov = context.read<OrderProvider>();

    switch (widget.order.status) {
      case OrderStatus.pendingPayment:
      case OrderStatus.paymentReview:
        return Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Confirmar pago',
                  color: AppColors.alertSuccess,
                  icon: Icons.check,
                  onTap: () => prov.updateOrderStatus(
                      widget.order.id, OrderStatus.confirmed))),
          const SizedBox(width: 8),
          Expanded(
              child: _ActionBtn(
                  label: 'Cancelar',
                  color: AppColors.alertError,
                  icon: Icons.close,
                  onTap: () => _cancelDialog(context, prov))),
        ]);

      case OrderStatus.confirmed:
        return Row(children: [
          Expanded(
              child: _ActionBtn(
                  label: 'Marcar listo',
                  color: AppColors.secondary,
                  icon: Icons.inventory_outlined,
                  onTap: () => prov.updateOrderStatus(
                      widget.order.id, OrderStatus.readyForPickup))),
          const SizedBox(width: 8),
          Expanded(
              child: _ActionBtn(
                  label: 'Pedido Especial',
                  color: AppColors.alertInfo,
                  icon: Icons.factory_outlined,
                  onTap: () => prov.updateOrderStatus(
                      widget.order.id, OrderStatus.specialOrder))),
        ]);

      case OrderStatus.specialOrder:
        return _ActionBtn(
            label: 'Llegó de fábrica → Listo',
            color: AppColors.secondary,
            icon: Icons.local_shipping_outlined,
            onTap: () => prov.updateOrderStatus(
                widget.order.id, OrderStatus.readyForPickup));

      case OrderStatus.readyForPickup:
        return _ActionBtn(
            label: 'Marcar como entregado',
            color: AppColors.primary,
            icon: Icons.handshake_outlined,
            onTap: () =>
                prov.updateOrderStatus(widget.order.id, OrderStatus.delivered));

      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  void _cancelDialog(BuildContext context, OrderProvider prov) {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar pedido #${widget.order.id}',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Especifica el motivo (se notificará al alumno):',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ejemplo: Falta de insumos en fábrica',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () {
                // FIX: pop with dialogCtx, then dispose
                Navigator.pop(dialogCtx);
                ctrl.dispose();
              },
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              // FIX: snapshot reason BEFORE dispose/pop — reading after
              // dispose caused empty string or crash
              final reason = ctrl.text.trim();
              Navigator.pop(dialogCtx);
              ctrl.dispose();
              // prov is already captured from outer scope — safe to use
              prov.updateOrderStatus(
                widget.order.id,
                OrderStatus.cancelled,
                cancelReason: reason,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertError,
                minimumSize: const Size(80, 40)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  IconData _iconForPayment(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.transfer:
        return Icons.receipt_long_outlined;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
