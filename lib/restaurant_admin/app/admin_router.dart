import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/screens/login_screen.dart';
import '../ui/screens/orders_screen.dart';
import '../ui/screens/order_history_screen.dart';
import '../ui/screens/menu_screen.dart';
import '../ui/screens/menu_item_edit_screen.dart';
import '../ui/screens/order_details_screen.dart';
import 'admin_providers.dart';

/// تعريف أسماء المسارات لتسهيل استخدامها.
class AdminRoutes {
  static const login = '/login';
  static const orders = '/orders';
  static const orderDetails = '/orders/details';
  static const menu = '/menu';
  static const menuItemEdit = '/menu/edit';
  static const orderHistory = '/orders/history';
}

/// مزود GoRouter يستخدم [authStateChangesProvider] للتحقق من حالة تسجيل الدخول.
final adminRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authStateChangesProvider.stream);
  final authState = ref.watch(authStateChangesProvider);
  final isAdminMode = ref.watch(adminModeProvider);

  return GoRouter(
    initialLocation: AdminRoutes.login,
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) {
      final isLoggedInFromAuth = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
      final isLoggedIn = isLoggedInFromAuth || isAdminMode;
      final currentPath = state.uri.path;
      final isLoggingIn = currentPath == AdminRoutes.login;

      if (!isLoggedIn) {
        return isLoggingIn ? null : AdminRoutes.login;
      }

      if (isLoggingIn) {
        return AdminRoutes.orders;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AdminRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AdminRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: AdminRoutes.orderHistory,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: AdminRoutes.menu,
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: AdminRoutes.orderDetails,
        builder: (context, state) {
          final orderId = state.extra as String?;
          return OrderDetailsScreen(orderId: orderId ?? '');
        },
      ),
      GoRoute(
        path: AdminRoutes.menuItemEdit,
        builder: (context, state) {
          final itemId = state.extra as String?;
          return MenuItemEditScreen(itemId: itemId);
        },
      ),
    ],
  );
});

/// دعم لتحديث GoRouter عند تغير بيانات Riverpod.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
