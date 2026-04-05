import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/admin_providers.dart';
import '../../core/admin_failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/watch_active_orders_usecase.dart';
import '../../domain/usecases/watch_completed_orders_usecase.dart';
import '../../domain/usecases/get_order_by_id_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';
import '../../domain/usecases/update_order_driver_usecase.dart';
import '../../domain/usecases/search_orders_usecase.dart';
import 'auth_viewmodel.dart';
import '../../../utils/i18n.dart';

/// الحالة الخاصة بالطلبات المعروضة في لوحة المسؤول.
class OrdersState {
  const OrdersState({
    this.activeOrders = const [],
    this.completedOrders = const [],
    this.isLoadingActive = false,
    this.isLoadingCompleted = false,
    this.errorMessage,
    this.dateFilter,
    this.searchQuery,
    this.selectedOrder,
  });

  final List<Order> activeOrders;
  final List<Order> completedOrders;
  final bool isLoadingActive;
  final bool isLoadingCompleted;
  final String? errorMessage;
  final DateTimeRange? dateFilter;
  final String? searchQuery;
  final Order? selectedOrder;

  OrdersState copyWith({
    List<Order>? activeOrders,
    List<Order>? completedOrders,
    bool? isLoadingActive,
    bool? isLoadingCompleted,
    String? errorMessage,
    DateTimeRange? dateFilter,
    String? searchQuery,
    Order? selectedOrder,
  }) {
    return OrdersState(
      activeOrders: activeOrders ?? this.activeOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      isLoadingCompleted: isLoadingCompleted ?? this.isLoadingCompleted,
      errorMessage: errorMessage,
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedOrder: selectedOrder ?? this.selectedOrder,
    );
  }
}

/// الـ ViewModel المسؤول عن مراقبة الطلبات الجديدة والسابقة وتحديث حالتها.
class OrdersViewModel extends StateNotifier<OrdersState> {
  OrdersViewModel(
    this._watchActiveOrders,
    this._watchCompletedOrders,
    this._getOrderById,
    this._updateOrderStatus,
    this._updateOrderDriver,
    this._searchOrders,
  ) : super(const OrdersState());

  final WatchActiveOrdersUseCase _watchActiveOrders;
  final WatchCompletedOrdersUseCase _watchCompletedOrders;
  final GetOrderByIdUseCase _getOrderById;
  final UpdateOrderStatusUseCase _updateOrderStatus;
  final UpdateOrderDriverUseCase _updateOrderDriver;
  final SearchOrdersUseCase _searchOrders;

  StreamSubscription<List<Order>>? _activeSub;
  StreamSubscription<List<Order>>? _completedSub;
  String? _restaurantId;

  /// بدء مراقبة الطلبات بمجرد توفر معرف المطعم.
  void initialize(String restaurantId) {
    print(
      '🔄 OrdersViewModel.initialize called with restaurantId: $restaurantId',
    );
    if (_restaurantId == restaurantId) {
      print('⚠️ Same restaurantId, skipping re-initialization');
      return;
    }
    _restaurantId = restaurantId;
    _listenActiveOrders();
    _listenCompletedOrders();
  }

  void _listenActiveOrders() {
    if (_restaurantId == null) {
      print('❌ restaurantId is null in _listenActiveOrders');
      return;
    }
    print('🔍 Starting to listen to active orders for: $_restaurantId');
    state = state.copyWith(isLoadingActive: true, errorMessage: null);
    _activeSub?.cancel();
    _activeSub = _watchActiveOrders(restaurantId: _restaurantId!).listen(
      (orders) {
        print('✅ Received ${orders.length} active orders');
        state = state.copyWith(
          activeOrders: orders,
          isLoadingActive: false,
          errorMessage: null,
        );
      },
      onError: (error, stackTrace) {
        print('❌ Error listening to active orders: $error');
        print('Stack trace: $stackTrace');
        state = state.copyWith(
          isLoadingActive: false,
          errorMessage: tNoContext(
            'Failed to load active orders: $error',
            'Не удалось загрузить новые заказы: $error',
          ),
        );
      },
    );
  }

  void _listenCompletedOrders({DateTime? start, DateTime? end}) {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoadingCompleted: true, errorMessage: null);
    _completedSub?.cancel();
    _completedSub =
        _watchCompletedOrders(
          restaurantId: _restaurantId!,
          startDate: start,
          endDate: end,
        ).listen(
          (orders) {
            state = state.copyWith(
              completedOrders: orders,
              isLoadingCompleted: false,
              errorMessage: null,
            );
          },
          onError: (error) {
            state = state.copyWith(
              isLoadingCompleted: false,
              // Don't block current orders screen if completed orders fail.
              errorMessage: state.errorMessage,
            );
          },
        );
  }

  /// تغيير فلترة التاريخ.
  void applyDateFilter(DateTimeRange? range) {
    state = state.copyWith(dateFilter: range);
    _listenCompletedOrders(start: range?.start, end: range?.end);
  }

  /// البحث عن الطلبات حسب رقم الطلب أو اسم العميل.
  Future<void> searchOrders({String? orderNumber, String? customerName}) async {
    if (_restaurantId == null) return;
    state = state.copyWith(
      isLoadingCompleted: true,
      searchQuery: orderNumber ?? customerName,
      errorMessage: null,
    );
    try {
      final results = await _searchOrders(
        restaurantId: _restaurantId!,
        orderNumber: orderNumber,
        customerName: customerName,
      );
      state = state.copyWith(
        completedOrders: results,
        isLoadingCompleted: false,
      );
    } on Failure catch (failure) {
      state = state.copyWith(
        isLoadingCompleted: false,
        errorMessage: failure.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingCompleted: false,
        errorMessage: tNoContext(
          'Search failed: $error',
          'Ошибка поиска: $error',
        ),
      );
    }
  }

  /// جلب تفاصيل طلب محدد من Firestore.
  Future<void> loadOrderDetails(String orderId) async {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoadingActive: true, errorMessage: null);
    try {
      final order = await _getOrderById(
        restaurantId: _restaurantId!,
        orderId: orderId,
      );
      state = state.copyWith(selectedOrder: order, isLoadingActive: false);
    } on Failure catch (failure) {
      state = state.copyWith(
        isLoadingActive: false,
        errorMessage: failure.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingActive: false,
        errorMessage: tNoContext(
          'Failed to load order details: $error',
          'Не удалось загрузить детали заказа: $error',
        ),
      );
    }
  }

  /// تحديث حالة الطلب في Firestore وإرسال إشعار عبر Cloud Functions.
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoadingActive: true, errorMessage: null);
    try {
      await _updateOrderStatus(
        restaurantId: _restaurantId!,
        orderId: orderId,
        status: status,
      );
      state = state.copyWith(isLoadingActive: false);
    } on Failure catch (failure) {
      state = state.copyWith(
        isLoadingActive: false,
        errorMessage: failure.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingActive: false,
        errorMessage: tNoContext(
          'Failed to update order status: $error',
          'Не удалось обновить статус заказа: $error',
        ),
      );
    }
  }

  /// تحديث سائق الطلب.
  Future<void> updateOrderDriver({
    required String orderId,
    String? driverId,
    String? driverName,
  }) async {
    if (_restaurantId == null) return;
    state = state.copyWith(isLoadingActive: true, errorMessage: null);
    try {
      await _updateOrderDriver(
        restaurantId: _restaurantId!,
        orderId: orderId,
        driverId: driverId,
        driverName: driverName,
      );
      state = state.copyWith(isLoadingActive: false);
    } on Failure catch (failure) {
      state = state.copyWith(
        isLoadingActive: false,
        errorMessage: failure.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingActive: false,
        errorMessage: tNoContext(
          'Failed to update order driver: $error',
          'Не удалось обновить курьера заказа: $error',
        ),
      );
    }
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }
}

/// مزود ViewModel للطلبات، يعتمد على معرف المطعم.
final ordersViewModelProvider =
    StateNotifierProvider.autoDispose<OrdersViewModel, OrdersState>((ref) {
      final viewModel = OrdersViewModel(
        ref.watch(watchActiveOrdersUseCaseProvider),
        ref.watch(watchCompletedOrdersUseCaseProvider),
        ref.watch(getOrderByIdUseCaseProvider),
        ref.watch(updateOrderStatusUseCaseProvider),
        ref.watch(updateOrderDriverUseCaseProvider),
        ref.watch(searchOrdersUseCaseProvider),
      );

      ref.listen<AuthState>(authViewModelProvider, (_, state) {
        if (state.restaurantId != null) {
          viewModel.initialize(state.restaurantId!);
        }
      });

      final authState = ref.read(authViewModelProvider);
      if (authState.restaurantId != null) {
        viewModel.initialize(authState.restaurantId!);
      }

      // If admin mode (manual flag) is enabled but authState doesn't have a
      // restaurantId (e.g., local admin shortcut), initialize with a demo id.
      ref.listen<bool>(adminModeProvider, (_, isAdmin) {
        if (isAdmin) {
          final currentAuth = ref.read(authViewModelProvider);
          if (currentAuth.restaurantId == null) {
            viewModel.initialize('demo_restaurant');
          }
        }
      });

      return viewModel;
    });
