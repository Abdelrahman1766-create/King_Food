import 'package:cloud_functions/cloud_functions.dart';

import '../../core/admin_failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_datasource.dart';
import '../../../utils/i18n.dart';

/// تنفيذ مستودع الطلبات باستخدام Firestore وCloud Functions.
class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({
    required OrdersRemoteDataSource remoteDataSource,
    required FirebaseFunctions functions,
  }) : _remoteDataSource = remoteDataSource,
       _functions = functions;

  final OrdersRemoteDataSource _remoteDataSource;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Order>> watchActiveOrders({required String restaurantId}) {
    return _remoteDataSource
        .watchActiveOrders(restaurantId: restaurantId)
        .map((orders) => List<Order>.from(orders.map((o) => o.toEntity())));
  }

  @override
  Stream<List<Order>> watchCompletedOrders({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _remoteDataSource
        .watchCompletedOrders(
          restaurantId: restaurantId,
          startDate: startDate,
          endDate: endDate,
        )
        .map((orders) => List<Order>.from(orders.map((o) => o.toEntity())));
  }

  @override
  Stream<List<Order>> watchOrdersByDriver({
    required String restaurantId,
    required String driverId,
  }) {
    return _remoteDataSource
        .watchOrdersByDriver(restaurantId: restaurantId, driverId: driverId)
        .map((orders) => List<Order>.from(orders.map((o) => o.toEntity())));
  }

  @override
  Future<Order?> getOrderById({
    required String restaurantId,
    required String orderId,
  }) async {
    try {
      final orderModel = await _remoteDataSource.getOrderById(
        restaurantId: restaurantId,
        orderId: orderId,
      );
      return orderModel?.toEntity();
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to fetch order data: ${e.toString()}',
          'Не удалось получить данные заказа: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    try {
      await _remoteDataSource.updateOrderStatus(
        restaurantId: restaurantId,
        orderId: orderId,
        status: status,
      );
      await logOrderStatusChange(
        restaurantId: restaurantId,
        orderId: orderId,
        status: status,
        changedAt: DateTime.now(),
      );
      try {
        await _triggerOrderStatusNotification(
          restaurantId: restaurantId,
          orderId: orderId,
          status: status,
        );
      } catch (e) {
        // Ignore notification errors so order flow doesn't break if Cloud Functions is missing.
        print('Notification failed: $e');
      }
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to update order status: ${e.toString()}',
          'Не удалось обновить статус заказа: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<void> updateOrderDriver({
    required String restaurantId,
    required String orderId,
    String? driverId,
    String? driverName,
  }) async {
    try {
      await _remoteDataSource.updateOrderDriver(
        restaurantId: restaurantId,
        orderId: orderId,
        driverId: driverId,
        driverName: driverName,
      );
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to update order driver: ${e.toString()}',
          'Не удалось обновить курьера заказа: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _triggerOrderStatusNotification({
    required String restaurantId,
    required String orderId,
    required String status,
  }) async {
    try {
      await _functions.httpsCallable('sendOrderStatusNotification').call({
        'restaurantId': restaurantId,
        'orderId': orderId,
        'status': status,
      });
    } on FirebaseFunctionsException catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to send notification: ${e.message}',
          'Не удалось отправить уведомление: ${e.message}',
        ),
      );
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to send notification: ${e.toString()}',
          'Не удалось отправить уведомление: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<List<Order>> searchOrders({
    required String restaurantId,
    String? orderNumber,
    String? customerName,
  }) async {
    try {
      final orderModels = await _remoteDataSource.searchOrders(
        restaurantId: restaurantId,
        orderNumber: orderNumber,
        customerName: customerName,
      );
      return orderModels.map((model) => model.toEntity()).toList();
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to search orders: ${e.toString()}',
          'Не удалось выполнить поиск заказов: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<List<Order>> getOrdersByDriver({
    required String restaurantId,
    required String driverId,
  }) async {
    try {
      final orderModels = await _remoteDataSource.getOrdersByDriver(
        restaurantId: restaurantId,
        driverId: driverId,
      );
      return orderModels.map((model) => model.toEntity()).toList();
    } on Exception catch (e) {
      throw NetworkFailure(
        tNoContext(
          'Failed to fetch driver orders: ${e.toString()}',
          'Не удалось получить заказы курьера: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<void> logOrderStatusChange({
    required String restaurantId,
    required String orderId,
    required String status,
    required DateTime changedAt,
  }) {
    return _remoteDataSource.logOrderStatusChange(
      restaurantId: restaurantId,
      orderId: orderId,
      status: status,
      changedAt: changedAt,
    );
  }
}
