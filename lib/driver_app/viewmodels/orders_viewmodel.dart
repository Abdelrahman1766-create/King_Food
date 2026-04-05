import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../restaurant_admin/domain/entities/order.dart';
import '../../restaurant_admin/domain/repositories/orders_repository.dart';
import 'auth_viewmodel.dart';
import '../../utils/i18n.dart';

/// حالة ViewModel الطلبات للسائق.
class OrdersState {
  final List<Order> activeOrders;
  final bool isLoadingActive;
  final String? error;

  const OrdersState({
    this.activeOrders = const [],
    this.isLoadingActive = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? activeOrders,
    bool? isLoadingActive,
    String? error,
  }) {
    return OrdersState(
      activeOrders: activeOrders ?? this.activeOrders,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      error: error ?? this.error,
    );
  }
}

/// ViewModel لإدارة الطلبات من منظور السائق.
class OrdersViewModel extends StateNotifier<OrdersState> {
  final OrdersRepository _ordersRepository;
  final AuthViewModel _authViewModel;
  StreamSubscription<List<Order>>? _ordersSub;

  OrdersViewModel(this._ordersRepository, this._authViewModel)
    : super(const OrdersState());

  /// تهيئة ViewModel وتحميل الطلبات المخصصة للسائق.
  void initialize(String restaurantId) {
    _loadActiveOrders(restaurantId);
  }

  /// تحميل الطلبات النشطة المخصصة للسائق الحالي.
  Future<void> _loadActiveOrders(String restaurantId) async {
    state = state.copyWith(isLoadingActive: true, error: null);
    await _ordersSub?.cancel();

    final driverId = _authViewModel.state.driverId;
    if (driverId == null) {
      state = state.copyWith(
        isLoadingActive: false,
        error: tNoContext(
          'Driver ID is not available',
          'Идентификатор курьера недоступен',
        ),
      );
      return;
    }

    _ordersSub = _ordersRepository
        .watchOrdersByDriver(restaurantId: restaurantId, driverId: driverId)
        .listen(
          (orders) {
            state = state.copyWith(
              activeOrders: orders,
              isLoadingActive: false,
              error: null,
            );
          },
          onError: (e) {
            final message = e.toString();
            state = state.copyWith(
              isLoadingActive: false,
              error: tNoContext(
                'Failed to load orders: $message',
                'Не удалось загрузить заказы: $message',
              ),
            );
            if (message.contains('permission-denied')) {
              Future.delayed(const Duration(seconds: 1), () {
                _loadActiveOrders(restaurantId);
              });
            }
          },
        );
  }

  /// تحديث حالة الطلب.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final restaurantId = _authViewModel.state.restaurantId;
      if (restaurantId == null) {
        state = state.copyWith(
          error: tNoContext(
            'Restaurant ID is not available',
            'Идентификатор ресторана недоступен',
          ),
        );
        return;
      }

      await _ordersRepository.updateOrderStatus(
        restaurantId: restaurantId,
        orderId: orderId,
        status: status,
      );

      // تحديث الحالة محليًا
      final updatedOrders = state.activeOrders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: status);
        }
        return order;
      }).toList();

      state = state.copyWith(activeOrders: updatedOrders);
    } catch (e) {
      state = state.copyWith(
        error: tNoContext(
          'Failed to update order status: $e',
          'Не удалось обновить статус заказа: $e',
        ),
      );
    }
  }

  /// تحديث البيانات عند تغيير السائق.
  void onDriverChanged(String restaurantId) {
    _loadActiveOrders(restaurantId);
  }

  void reset() {
    _ordersSub?.cancel();
    state = const OrdersState();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }
}
