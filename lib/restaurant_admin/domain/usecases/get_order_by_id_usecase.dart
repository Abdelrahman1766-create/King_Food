import '../entities/order.dart';
import '../repositories/orders_repository.dart';

/// UseCase لجلب طلب محدد بالتفصيل.
class GetOrderByIdUseCase {
  GetOrderByIdUseCase(this._repository);

  final OrdersRepository _repository;

  Future<Order?> call({
    required String restaurantId,
    required String orderId,
  }) {
    return _repository.getOrderById(
      restaurantId: restaurantId,
      orderId: orderId,
    );
  }
}
