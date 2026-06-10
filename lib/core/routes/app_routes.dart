// lib/core/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import 'route_transitions.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/alumno/catalog_screen.dart';
import '../../screens/alumno/product_detail_screen.dart';
import '../../screens/alumno/cart_screen.dart';
import '../../screens/alumno/checkout_screen.dart';
import '../../screens/alumno/notifications_screen.dart';
import '../../screens/alumno/my_orders_screen.dart';
import '../../screens/alumno/profile_screen.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/orders_screen.dart';
import '../../screens/admin/inventory_screen.dart';
import '../../screens/admin/analytics_screen.dart';
import '../../screens/admin/discounts_screen.dart';
import '../../screens/admin/add_product_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/registro';
  static const catalog = '/catalogo';
  static const productDetail = '/catalogo/detalle';
  static const cart = '/carrito';
  static const checkout = '/checkout';
  static const adminHome = '/admin';
  static const orders = '/admin/pedidos';
  static const inventory = '/admin/inventario';
  static const analytics = '/admin/analiticas';
  static const discounts = '/admin/descuentos';
  static const addProduct = '/admin/agregar-producto';
  static const notifications = '/notificaciones';
  static const myOrders = '/mis-pedidos';
  static const profile = '/perfil';
}

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: auth,
    redirect: (BuildContext context, GoRouterState state) {
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      final isOnRegister = state.matchedLocation == AppRoutes.register;

      if (!auth.isAuthenticated) {
        if (isOnLogin || isOnRegister) return null;
        return AppRoutes.login;
      }

      if (isOnLogin || isOnRegister) {
        return auth.isAdmin ? AppRoutes.adminHome : AppRoutes.catalog;
      }

      if (auth.isAdmin &&
          !state.matchedLocation.startsWith('/admin') &&
          state.matchedLocation != AppRoutes.profile) {
        return AppRoutes.adminHome;
      }

      if (!auth.isAdmin && state.matchedLocation.startsWith('/admin')) {
        return AppRoutes.catalog;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, __) => buildFadeTransition(const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, __) => buildFadeTransition(const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.catalog,
        pageBuilder: (_, __) => buildSlideTransition(const CatalogScreen()),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        pageBuilder: (_, state) => buildSlideTransition(
          ProductDetailScreen(productId: state.extra as String),
        ),
      ),
      // FIX: carrito y checkout usan transición bottom (más natural para modales)
      GoRoute(
        path: AppRoutes.cart,
        pageBuilder: (_, __) => buildBottomSlideTransition(const CartScreen()),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (_, __) =>
            buildBottomSlideTransition(const CheckoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        pageBuilder: (_, __) => buildFadeTransition(const AdminHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.orders,
        pageBuilder: (_, __) => buildSlideTransition(const OrdersScreen()),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        pageBuilder: (_, __) => buildSlideTransition(const InventoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        pageBuilder: (_, __) => buildSlideTransition(const AnalyticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.discounts,
        pageBuilder: (_, __) => buildSlideTransition(const DiscountsScreen()),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        pageBuilder: (_, __) =>
            buildBottomSlideTransition(const AddProductScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (_, __) =>
            buildSlideTransition(const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.myOrders,
        pageBuilder: (_, __) => buildSlideTransition(const MyOrdersScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (_, __) => buildSlideTransition(const ProfileScreen()),
      ),
    ],
  );
}
