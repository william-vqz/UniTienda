import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/notification_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniTiendaApp());
}

class UniTiendaApp extends StatefulWidget {
  const UniTiendaApp({super.key});
  @override
  State<UniTiendaApp> createState() => _UniTiendaAppState();
}

class _UniTiendaAppState extends State<UniTiendaApp> {
  late final AuthProvider _auth;
  late final ProductProvider _products;
  late final OrderProvider _orders;
  late final NotificationProvider _notifications;
  late final CartProvider _cart;
  late final CouponProvider _coupon;
  late final GoRouter _router;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _products = ProductProvider();
    _orders = OrderProvider();
    _notifications = NotificationProvider();
    // FIX: Create CartProvider and CouponProvider here so they live in MultiProvider
    // from the very first frame — prevents _dependents.isEmpty assertion errors
    _cart = CartProvider();
    _coupon = CouponProvider();
    _router = createRouter(_auth);
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _auth.restoreSession(),
      _products.fetchProducts(),
      _orders.fetchOrders(),
    ]);

    _orders.setNotificationProvider(_notifications);

    if (_auth.isAlumno && mounted) {
      await _notifications.fetchNotifications(_auth.studentId);
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: MultiProvider always wraps the widget tree so providers are available
    // both during loading AND after initialization — fixes the red screen crash.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _products),
        ChangeNotifierProvider.value(value: _orders),
        ChangeNotifierProvider.value(value: _notifications),
        // FIX: Use .value so the same instance is reused across rebuilds
        ChangeNotifierProvider.value(value: _cart),
        ChangeNotifierProvider.value(value: _coupon),
      ],
      child: !_initialized
          ? MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: AppColors.primary,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('UniTienda',
                          style: GoogleFonts.nunito(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('CBTis 272 · Cancún',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.white70,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(color: Colors.white),
                    ],
                  ),
                ),
              ),
            )
          : MaterialApp.router(
              title: 'UniTienda — CBTis 272',
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              theme: _buildTheme(),
              themeMode: ThemeMode.dark,
            ),
    );
  }

  ThemeData _buildTheme() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.alertError,
      onPrimary: AppColors.textOnDark,
      onSecondary: AppColors.textOnDark,
      onSurface: AppColors.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunito(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
        titleLarge: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        titleMedium: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary),
        labelLarge: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark,
            letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnDark,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.nunito(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.alertError)),
        labelStyle:
            GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: AppColors.shadow,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle:
            GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDisabled,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
