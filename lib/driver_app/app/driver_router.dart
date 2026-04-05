import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/screens/login_screen.dart';
import '../ui/screens/orders_screen.dart';
import '../ui/screens/order_details_screen.dart';
import 'driver_app.dart';

/// تعريف أسماء المسارات لتسهيل استخدامها.
class DriverRoutes {
  static const login = '/login';
  static const orders = '/orders';
  static const orderDetails = '/orders/details';
}

/// مزود GoRouter يستخدم [authStateChangesProvider] للتحقق من حالة تسجيل الدخول.
final driverRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: DriverRoutes.login,
    redirect: (context, state) {
      final isLoggedIn = authStateAsync.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );
      final currentPath = state.uri.path;
      final isLoggingIn = currentPath == DriverRoutes.login;

      if (!isLoggedIn) {
        return isLoggingIn ? null : DriverRoutes.login;
      }

      if (isLoggingIn) {
        return DriverRoutes.orders;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: DriverRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: DriverRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: DriverRoutes.orderDetails,
        builder: (context, state) {
          final orderId = state.extra as String?;
          if (orderId == null) return const OrdersScreen();
          return OrderDetailsScreen(orderId: orderId);
        },
      ),
    ],
  );
});
