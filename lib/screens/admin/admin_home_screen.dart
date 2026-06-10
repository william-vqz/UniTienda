// lib/screens/admin/admin_home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/currency_formatter.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ProductProvider>();
      if (p.products.isEmpty && !p.isLoading) p.fetchProducts();
      // FIX: también refrescar pedidos al entrar al panel
      context.read<OrderProvider>().refreshOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final pendingCount = orders.pendingOrders.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: const _DashboardBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) {
          switch (i) {
            case 0:
              setState(() => _currentTab = 0);
            case 1:
              setState(() => _currentTab = 1);
              context.push(AppRoutes.orders).then((_) {
                if (mounted) setState(() => _currentTab = 0);
              });
            case 2:
              setState(() => _currentTab = 2);
              context.push(AppRoutes.inventory).then((_) {
                if (mounted) setState(() => _currentTab = 0);
              });
            case 3:
              setState(() => _currentTab = 3);
              context.push(AppRoutes.analytics).then((_) {
                if (mounted) setState(() => _currentTab = 0);
              });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            activeIcon: const Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analíticas',
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  // FIX: dialog de logout usa dialogCtx para Navigator.pop — no outer context
  void _showLogoutConfirm(BuildContext context) {
    final outerCtx = context;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              outerCtx.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertError,
                minimumSize: const Size(80, 40)),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final products = context.watch<ProductProvider>();

    final pending = orders.ordersByStatus(OrderStatus.pendingPayment).length +
        orders.ordersByStatus(OrderStatus.paymentReview).length;
    final ready = orders.ordersByStatus(OrderStatus.readyForPickup).length;
    final special = orders.ordersByStatus(OrderStatus.specialOrder).length;
    final totalSales = orders.orders
        .where((o) => !o.isCancelled)
        .fold(0.0, (s, o) => s + o.total);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 130,
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: auth.currentUser?.profileImage != null &&
                        auth.currentUser!.profileImage!.isNotEmpty
                    ? FileImage(File(auth.currentUser!.profileImage!))
                    : null,
                child: (auth.currentUser?.profileImage == null ||
                        auth.currentUser!.profileImage!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              tooltip: 'Mi Perfil',
              onPressed: () => context.push(AppRoutes.profile),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _showLogoutConfirm(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, ${auth.displayName}',
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('Panel UniTienda · CBTis 272',
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
            background: Container(color: AppColors.primary),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _KpiCard(
                      label: 'Por verificar',
                      value: '$pending',
                      icon: Icons.hourglass_empty_rounded,
                      color: AppColors.alertWarning),
                  _KpiCard(
                      label: 'Listos entrega',
                      value: '$ready',
                      icon: Icons.check_circle_outline,
                      color: AppColors.alertSuccess),
                  _KpiCard(
                      label: 'Pedidos especiales',
                      value: '$special',
                      icon: Icons.factory_outlined,
                      color: AppColors.alertInfo),
                  _KpiCard(
                      label: 'Ventas totales',
                      value: formatMxn(totalSales),
                      icon: Icons.attach_money,
                      color: AppColors.secondary),
                ],
              ),
              const SizedBox(height: 24),
              Text('Acciones rápidas',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _QuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'Gestionar Pedidos',
                subtitle: '${orders.pendingOrders.length} pedidos activos',
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.orders),
              ),
              const SizedBox(height: 10),
              _QuickAction(
                icon: Icons.inventory_2_outlined,
                label: 'Control de Inventario',
                subtitle: '${products.products.length} productos en catálogo',
                color: AppColors.secondary,
                onTap: () => context.push(AppRoutes.inventory),
              ),
              const SizedBox(height: 10),
              _QuickAction(
                icon: Icons.bar_chart_outlined,
                label: 'Ver Analíticas BI',
                subtitle: 'Top ventas y flujo de ingresos',
                color: AppColors.alertInfo,
                onTap: () => context.push(AppRoutes.analytics),
              ),
              const SizedBox(height: 10),
              _QuickAction(
                icon: Icons.discount_outlined,
                label: 'Cupones de Descuento',
                subtitle: 'Gestionar promociones y cupones',
                color: AppColors.alertSuccess,
                onTap: () => context.push(AppRoutes.discounts),
              ),
              const SizedBox(height: 24),
              Text('Pedidos recientes',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              if (orders.orders.isEmpty)
                Center(
                  child: Text('Aún no hay pedidos registrados.',
                      style:
                          GoogleFonts.nunito(color: AppColors.textSecondary)),
                )
              else
                ...orders.orders.take(3).map((o) => _RecentOrderTile(order: o)),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380)); // FIX: 500 → 380ms
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: widget.color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.icon, color: widget.color, size: 18),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(widget.value,
                  style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: widget.color)),
            ),
            Text(widget.label,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        // FIX: InkWell en vez de GestureDetector → feedback visual táctil
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Order order;
  const _RecentOrderTile({required this.order});

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
      case OrderStatus.cancelled:
        return AppColors.alertError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                  color: _statusColor, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${order.studentName} · #${order.id}',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(order.status.label,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: _statusColor,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatMxn(order.total),
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
