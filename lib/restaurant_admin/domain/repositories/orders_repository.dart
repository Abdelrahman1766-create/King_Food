import '../entities/order.dart';

/// واجهة لمستودع الطلبات.
abstract class OrdersRepository {
  /// بث للطلبات الجديدة أو الطلبات تحت المعالجة بحسب الحالة.
  Stream<List<Order>> watchActiveOrders({required String restaurantId});

  /// بث للطلبات السابقة (تم التوصيل).
  Stream<List<Order>> watchCompletedOrders({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// بث للطلبات المخصصة لسائق محدد.
  Stream<List<Order>> watchOrdersByDriver({
    required String restaurantId,
    required String driverId,
  });

  /// جلب طلب محدد بالتفصيل.
  Future<Order?> getOrderById({
    required String restaurantId,
    required String orderId,
  });

  /// تحديث حالة الطلب.
  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  });

  /// تحديث سائق الطلب.
  Future<void> updateOrderDriver({
    required String restaurantId,
    required String orderId,
    String? driverId,
    String? driverName,
  });

  /// البحث عن طلبات بحسب الاسم أو رقم الطلب.
  Future<List<Order>> searchOrders({
    required String restaurantId,
    String? orderNumber,
    String? customerName,
  });

  /// جلب الطلبات المخصصة لسائق محدد.
  Future<List<Order>> getOrdersByDriver({
    required String restaurantId,
    required String driverId,
  });

  /// توثيق تغيير حالة الطلب (اختياري للتوسع).
  Future<void> logOrderStatusChange({
    required String restaurantId,
    required String orderId,
    required String status,
    required DateTime changedAt,
  });
}
