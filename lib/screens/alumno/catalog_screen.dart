// lib/screens/alumno/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/product_image.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/slide_fade_in.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _selectedCategory = 'Todos';

  // FIX: logout dialog usa dialogCtx para pop, outerCtx para leer provider
  void _logout(BuildContext context) {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ProductProvider>();
      if (p.products.isEmpty && !p.isLoading) p.fetchProducts();
      final auth = context.read<AuthProvider>();
      if (auth.isAlumno) {
        context.read<NotificationProvider>().fetchNotifications(auth.studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final products = context.watch<ProductProvider>();
    final notif = context.watch<NotificationProvider>();
    final filtered = products.byCategory(_selectedCategory);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, auth, cart, notif),
      body: products.isLoading
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerProductCard(),
            )
          : products.error != null
              ? _buildError(products)
              : Column(children: [
                  _buildCategoryFilters(products.categories),
                  Expanded(child: _buildGrid(filtered)),
                ]),
    );
  }

  AppBar _buildAppBar(BuildContext context, AuthProvider auth,
      CartProvider cart, NotificationProvider notif) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Column(children: [
        const Text(AppStrings.catalogTitle),
        Text('Hola, ${auth.displayName}',
            style: GoogleFonts.nunito(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.80),
                fontWeight: FontWeight.w500)),
      ]),
      actions: [
        // FIX: PopupMenu → íconos directos para reducir taps
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          tooltip: 'Mis pedidos',
          onPressed: () => context.push(AppRoutes.myOrders),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push(AppRoutes.notifications),
            ),
            if (notif.unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.cartBadge, shape: BoxShape.circle),
                  child: Text('${notif.unreadCount}',
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.push(AppRoutes.cart),
            ),
            if (cart.totalUnits > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.cartBadge, shape: BoxShape.circle),
                  child: Text('${cart.totalUnits}',
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
        // FIX: ícono de perfil + logout en menú compacto
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {
            if (v == 'profile') context.push(AppRoutes.profile);
            if (v == 'logout') _logout(context);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'profile',
                child: Row(children: [
                  Icon(Icons.person_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Mi Perfil')
                ])),
            const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 20, color: AppColors.alertError),
                  SizedBox(width: 12),
                  Text('Cerrar sesión',
                      style: TextStyle(color: AppColors.alertError))
                ])),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildCategoryFilters(List<String> categories) {
    return Container(
      height: 52,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = cat),
            labelStyle: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary),
            backgroundColor: AppColors.surfaceVariant,
            selectedColor: AppColors.primary,
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Product> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('Sin productos en esta categoría.',
            style: GoogleFonts.nunito(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      // FIX: pull-to-refresh en catálogo
      color: AppColors.primary,
      onRefresh: () => context.read<ProductProvider>().fetchProducts(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) => SlideFadeIn(
          index: i,
          child: _ProductCard(product: list[i]),
        ),
      ),
    );
  }

  Widget _buildError(ProductProvider p) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text(p.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: p.fetchProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // FIX: InkWell para feedback táctil al tocar
        onTap: () => context.push(AppRoutes.productDetail, extra: product.id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Hero(
                    tag: 'product-image-${product.id}',
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surfaceVariant,
                      child: ProductImage(imageUrl: product.imageUrl),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.category.toUpperCase(),
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(formatMxn(product.price),
                                style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary))),
                        if (!product.hasAnyStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.alertError
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text('Agotado',
                                style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.alertError)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
