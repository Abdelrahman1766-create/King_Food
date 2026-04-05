import '../../domain/repositories/orders_repository.dart';

/// حالة الاستخدام لتحديث سائق الطلب.
class UpdateOrderDriverUseCase {
  UpdateOrderDriverUseCase(this._repository);

  final OrdersRepository _repository;

  /// يحدث سائق الطلب المحدد.
  Future<void> call({
    required String restaurantId,
    required String orderId,
    String? driverId,
    String? driverName,
  }) {
    return _repository.updateOrderDriver(
      restaurantId: restaurantId,
      orderId: orderId,
      driverId: driverId,
      driverName: driverName,
    );
  }
}
