// lib/screens/alumno/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/currency_formatter.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final myOrders = orders.ordersForStudent(auth.studentId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mis Pedidos'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Activos'), Tab(text: 'Historial')],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // FIX: pull-to-refresh en mis pedidos
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<OrderProvider>().refreshOrders(),
              child: _ActiveOrdersList(
                  orders: myOrders.where((o) => !o.isFinalStatus).toList()),
            ),
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<OrderProvider>().refreshOrders(),
              child: _HistoryOrdersList(
                  orders: myOrders.where((o) => o.isFinalStatus).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrdersList extends StatelessWidget {
  final List<Order> orders;
  const _ActiveOrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      // FIX: ListView vacío para que RefreshIndicator funcione aunque no haya items
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text('No tienes pedidos activos',
                      style: GoogleFonts.nunito(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Jala hacia abajo para actualizar',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.textDisabled)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _OrderTrackingCard(order: orders[i]),
    );
  }
}

class _HistoryOrdersList extends StatelessWidget {
  final List<Order> orders;
  const _HistoryOrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_outlined,
                      size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text('No hay pedidos en el historial',
                      style: GoogleFonts.nunito(
                          fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _HistoryOrderCard(order: orders[i]),
    );
  }
}

class _OrderTrackingCard extends StatelessWidget {
  final Order order;
  const _OrderTrackingCard({required this.order});

  int get _currentStep {
    switch (order.status) {
      case OrderStatus.pendingPayment:
      case OrderStatus.paymentReview:
        return 0;
      case OrderStatus.confirmed:
      case OrderStatus.specialOrder:
        return 1;
      case OrderStatus.readyForPickup:
        return 2;
      case OrderStatus.delivered:
        return 3;
      default:
        return 0;
    }
  }

  Color get _statusColor {
    switch (order.status) {
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
      default:
        return AppColors.textDisabled;
    }
  }

  String get _statusText {
    switch (order.status) {
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
      default:
        return order.status.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido #${order.id}',
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                        '${order.items.length} productos · ${formatMxn(order.total)}',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusText,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  _buildStep(0, 'Pago', Icons.payment, _currentStep >= 0,
                      _statusColor),
                  Expanded(child: _buildLine(_currentStep >= 0, _statusColor)),
                  _buildStep(1, 'Confirmado', Icons.check_circle,
                      _currentStep >= 1, _statusColor),
                  Expanded(child: _buildLine(_currentStep >= 1, _statusColor)),
                  _buildStep(2, 'Listo', Icons.inventory, _currentStep >= 2,
                      _statusColor),
                  Expanded(child: _buildLine(_currentStep >= 2, _statusColor)),
                  _buildStep(3, 'Entregado', Icons.done_all, _currentStep >= 3,
                      _statusColor),
                ]),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                          '• ${item.name} (Talla ${item.size}) x${item.quantity}',
                          style: GoogleFonts.nunito(
                              fontSize: 13, color: AppColors.textSecondary)),
                    )),
                if (order.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+${order.items.length - 3} productos más',
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppColors.textDisabled)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
      int step, String label, IconData icon, bool isActive, Color color) {
    return Column(children: [
      AnimatedContainer(
        // FIX: animación suave en cambio de estado
        duration: const Duration(milliseconds: 300),
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? color : AppColors.surfaceVariant,
          border: Border.all(
              color: isActive ? color : AppColors.border, width: 1.5),
        ),
        child: Icon(icon,
            size: 20, color: isActive ? Colors.white : AppColors.textDisabled),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? color : AppColors.textDisabled)),
    ]);
  }

  Widget _buildLine(bool isActive, Color color) {
    return AnimatedContainer(
      // FIX: línea con animación suave
      duration: const Duration(milliseconds: 300),
      height: 2,
      color: isActive ? color : AppColors.border,
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  final Order order;
  const _HistoryOrderCard({required this.order});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pedido #${order.id}',
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.isCancelled
                      ? AppColors.alertError.withValues(alpha: 0.1)
                      : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(order.status.label,
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: order.isCancelled
                            ? AppColors.alertError
                            : AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today,
                size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(_formatDate(order.createdAt),
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(
                      child: Text('• ${item.name} (Talla ${item.size})',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppColors.textSecondary))),
                  Text('x${item.quantity}',
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ]),
              )),
          if (order.items.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${order.items.length - 2} productos más',
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textDisabled)),
            ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total pagañfdo:',
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(formatMxn(order.total),
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary))),
            ],
          ),
        ],
      ),
    );
  }
}
