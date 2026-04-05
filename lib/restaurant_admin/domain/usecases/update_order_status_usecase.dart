import '../repositories/orders_repository.dart';

/// UseCase لتحديث حالة الطلب وإعادتها إلى المستودع.
class UpdateOrderStatusUseCase {
  UpdateOrderStatusUseCase(this._repository);

  final OrdersRepository _repository;

  Future<void> call({
    required String restaurantId,
    required String orderId,
    required String status,
  }) {
    return _repository.updateOrderStatus(
      restaurantId: restaurantId,
      orderId: orderId,
      status: status,
    );
  }
}
